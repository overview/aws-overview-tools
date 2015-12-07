#!/bin/bash

# Starts up an Overview environment on a single EC2 instance, attaching volumes
# and elastic IPs.

fatal() {
  >&2 echo "$1"
  exit 1
}

usage() {
  >&2 echo "Usage: $0 ENVIRONMENT"
  >&2 echo
  >&2 echo "For instance: '$0 staging'"
  exit 1
}

: ${AWS_ACCESS_KEY_ID:?'You must set the AWS_ACCESS_KEY_ID environment variable'}
: ${AWS_SECRET_ACCESS_KEY:?'You must set the AWS_SECRET_ACCESS_KEY environment variable'}
: ${AWS_DEFAULT_REGION:?'You must set the AWS_DEFAULT_REGION environment variable'}
: ${OVERVIEW_MANAGE_HOST:?'You must set the OVERVIEW_MANAGE_HOST environment variable, e.g., "ubuntu@ec2-12-34-56-78.compute-1.amazonaws.com"'}
type -p aws >/dev/null || fatal 'You need the `aws` command in your $PATH'
type -p ssh >/dev/null || fatal 'You need the `ssh` command in your $PATH'

DIR="$(dirname $0)"
OVERVIEW_ENVIRONMENT=$1
[ "$OVERVIEW_ENVIRONMENT" = "staging" ] || [ "$OVERVIEW_ENVIRONMENT" = "production" ] || usage
AVAILABILITY_ZONE=us-east-1a
BASE_IMAGE=ami-dfcab0b5 # https://cloud-images.ubuntu.com/releases/wily/release/ us-east-1 64-bit hvm
VPC_ID=vpc-5c3fd138 # Name `overview`, CIDR block 10.0.0.0/16
SUBNET_ID=subnet-1e134747 # Name `overview`, VPC `overview`, zone $AVAILABILITY_ZONE, CIDR block `10.0.0.0/24`, auto-assign public IPs
INTERNET_GATEWAY_ID=igw-cab1efaf # Name `overview` attached to VPC `overview`, added as 0.0.0.0/0 to subnet route table

# Global variables: OVERVIEW_ENVIRONMENT and OVERVIEW_HOSTNAME
if [ "$OVERVIEW_ENVIRONMENT" = "staging" ]; then
  OVERVIEW_HOSTNAME=staging.overviewdocs.com
else
  OVERVIEW_HOSTNAME=www.overviewdocs.com
fi

wait_for_ssh() {
  success=$(ssh $OVERVIEW_MANAGE_HOST ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no $1 echo 'success' 2>/dev/null)
  if [ 'success' != "$success" ]; then
    >&2 echo "Sleeping waiting for $1 to respond to SSH..."
    sleep 5
    wait_for_ssh $1
  else
    >&2 echo "$1 is up"
  fi
}

wait_for_cloud_init() {
  line=$(do_ssh $1 ls /run/cloud-init/result.json 2>/dev/null)
  if [ '/run/cloud-init/result.json' != "$line" ]; then
    >&2 echo "Sleeping waiting for $1 to finish cloud-init..."
    sleep 5
    wait_for_cloud_init $1
  else
    >&2 echo "$1 is finished cloud-init"
  fi
}

do_ssh() {
  ip=$(shift)
  ssh $OVERVIEW_MANAGE_HOST ssh $ip "$@"
}

get_instance_ip() {
  aws ec2 describe-instances \
    --instance-ids $1 \
    --output text \
    --query 'Reservations[*].Instances[*].PrivateIpAddress'
}

get_volume_id() {
  aws ec2 describe-volumes \
    --filters "Name=tag:Name,Values=$1" \
    --query 'Volumes[*].VolumeId' \
    --output text
}

wait_for_instance_ip() {
  ip=$(get_instance_ip $1)
  if [ -z "$ip" ]; then
    >&2 echo "Waiting for $1 to get an ip address..."
    sleep 1
    wait_for_instance_ip $1
  else
    echo $ip
  fi
}

get_logstash_ip() {
  aws ec2 describe-instances \
    --filters \
      Name=tag:Name,Values=logstash \
      Name=vpc-id,Values=$VPC_ID \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text
}

get_database_snapshot_id() {
  aws ec2 describe-snapshots \
    --owner-ids self \
    --filter 'Name=description,Values="[database] Daily backup"' \
    --query 'Snapshots[*].SnapshotId' \
    | grep '"' | cut -d'"' -f2 | tail -n1
}

get_searchindex_snapshot_id() {
  aws ec2 describe-snapshots \
    --owner-ids self \
    --filter 'Name=description,Values="[searchindex] Daily backup"' \
    --query 'Snapshots[*].SnapshotId' \
    | grep '"' | cut -d'"' -f2 | tail -n1
}

get_instance_id() {
  aws ec2 describe-instances \
    --filters \
      Name=vpc-id,Values=$VPC_ID \
      Name=instance.group-name,Values=$OVERVIEW_ENVIRONMENT-$1 \
      Name=instance-state-name,Values=pending,running \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text
}

get_security_group_id() {
  aws ec2 describe-security-groups \
    --filters \
      Name=group-name,Values=$1 \
      Name=vpc-id,Values=$VPC_ID \
    --query 'SecurityGroups[*].GroupId' \
    --output text
}

get_ip_allocation_id() {
  aws ec2 describe-addresses \
    --filter Name=public-ip,Values=$1 \
    --query 'Addresses[*].AllocationId' \
    --output text
}

# Creates a temporary file that holds a cloud-init config.
#
# Arguments:
#   $1: SERVER
#
# The temporary file is created from cloud-init/$SERVER.txt, and all instances
# of #OVERVIEW_ENVIRONMENT# and #OVERVIEW_ENVIRONMENT_ADDRESS# within it are
# replaced with, say, "staging" and "staging.overviewproject.org".
generate_cloud_init_file() {
  logstash_ip=$(get_logstash_ip)
  if [ "$1" != 'logstash' -a -z "$logstash_ip" ]; then
    fatal "There's no logstash server, so you can't start any others. Launch the logstash environment first."
  fi

  ret=$(mktemp launch-overview-XXXXXX)
  cat "$DIR"/../cloud-init/$1.txt \
    | sed -e "s/#LOGSTASH_IP#/$logstash_ip/" \
    | sed -e "s/#OVERVIEW_ENVIRONMENT#/$OVERVIEW_ENVIRONMENT/" \
    | sed -e "s/#OVERVIEW_ENVIRONMENT_ADDRESS#/$OVERVIEW_HOSTNAME/" \
    > "$ret"

  echo $ret
}

ec2_run_instances() {
  instance_type=$1
  shift
  name=$1
  shift
  init_name=$1
  shift

  security_group_id=$(get_security_group_id $name)
  init_file=$(generate_cloud_init_file $init_name)

  aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --subnet-id $SUBNET_ID \
    --key-name manage \
    --instance-type $instance_type \
    --iam-instance-profile Name=$name \
    --security-group-ids $security_group_id \
    --user-data "file://$init_file" \
    "$@" \
    | grep 'InstanceId' | cut -d'"' -f4
  rm $init_file
}

run_staging_conglomerate() {
  database_snapshot_id=$(get_database_snapshot_id)
  searchindex_snapshot_id=$(get_searchindex_snapshot_id)

  ec2_run_instances r3.xlarge staging-conglomerate conglomerate \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"SnapshotId\":\"$database_snapshot_id\",\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\"}},{\"DeviceName\":\"/dev/sdg\",\"Ebs\":{\"SnapshotId\":\"$searchindex_snapshot_id\",\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\"}},{\"DeviceName\":\"/dev/sdb\",\"VirtualName\":\"ephemeral0\"}]"
}

run_production_conglomerate() {
  database_volume_id=$(get_volume_id 'production-database')
  searchindex_volume_id=$(get_volume_id 'production-searchindex')

  # Start the instance without its volume.
  instance_id=$(ec2_run_instances r3.xlarge production-conglomerate conglomerate --block-device-mappings "[{\"DeviceName\":\"/dev/sdb\",\"VirtualName\":\"ephemeral0\"}]")

  # Attach the volumes. There's a race here, but what are the odds we'll go from
  # null machine to Postgres/ElasticSearch up and running within 60s?
  sleep 60

  aws ec2 attach-volume \
    --volume-id $database_volume_id \
    --instance-id $instance_id \
    --device 'xvdf' \
    >/dev/null
  aws ec2 attach-volume \
    --volume-id $searchindex_volume_id \
    --instance-id $instance_id \
    --device 'xvdg' \
    >/dev/null

  echo $instance_id
}

run_conglomerate() {
  if [ 'staging' = "$OVERVIEW_ENVIRONMENT" ]; then
    run_staging_conglomerate
  else
    run_production_conglomerate
  fi
}

start_conglomerate() {
  instance_id=$(run_conglomerate)

  aws ec2 create-tags \
    --resources $instance_id \
    --tags \
      "Key=Name,Value=$OVERVIEW_ENVIRONMENT-conglomerate" \
      "Key=Environment,Value=$OVERVIEW_ENVIRONMENT" \
      >/dev/null
  >&2 echo "Launched conglomerate instance $instance_id"
}

start_conglomerate() {
  instance_id=$(get_instance_id conglomerate)
  if [ -z "$instance_id" ]; then
    >&2 echo "Launching conglomerate instance"
    instance_id=$(run_conglomerate)
  else
    >&2 echo "Found existing conglomerate instance"
  fi

  instance_ip=$(wait_for_instance_ip $instance_id)
  >&2 echo "Instance $instance_id has IP address $instance_ip"

  wait_for_ssh $instance_ip
  wait_for_cloud_init $instance_ip

  >&2 overview-manage add-instance $OVERVIEW_ENVIRONMENT/conglomerate/$instance_ip

  echo $instance_id
}

start_conglomerate

public_ip=$(dig +short $OVERVIEW_HOSTNAME)
allocation_id=$(get_ip_allocation_id $public_ip)
>&2 aws ec2 disassociate-address \
  --association-id $allocation_id \
  >/dev/null 2>&1 # usually, the association doesn't exist
>&2 aws ec2 associate-address \
  --instance-id $instance_id \
  --allocation-id $allocation_id \
  >/dev/null
>&2 echo "Instance $instance_id associated with public IP $public_ip"

>&2 echo "Done!"
