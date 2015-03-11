#!/bin/bash

# Starts up an Overview environment by launching EC2 instances, attaching
# volumes and attaching elastic IPs.
#
# HOW IT WORKS
#
# It:
# 1. starts a database instance. On staging it uses the latest daily snapshot
#    (It finds it by grepping descriptions.) On production it uses the volume
#    tagged "production-database".
#    PRODUCTION WARNING: unfortunately, you can't attach to a starting-up
#    instance. Use the EC2 console to attach production-database to
#    production-database as /dev/sdf while this script runs.
# 2. starts a searchindex instance. Same story as database -- if you're
#    starting production, use the EC2 console to attach while booting. You're
#    on the clock here.
# 3. starts a worker instance.
# 4. starts a web instance.
# 5. waits for each instance in turn to respond to SSH and then finish its
#    startup scripts. Once that happens, the environment has been launched.

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
BASE_IMAGE=ami-f0693098 # https://cloud-images.ubuntu.com/utopic/current/ us-east-1 64-bit hvm

# Global variables: OVERVIEW_ENVIRONMENT and OVERVIEW_HOSTNAME
if [ "$OVERVIEW_ENVIRONMENT" = "staging" ]; then
  OVERVIEW_HOSTNAME=staging.overviewproject.org
else
  OVERVIEW_HOSTNAME=www.overviewproject.org
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
    --output text \
    --query 'Volumes[*].VolumeId'
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
      "Name=instance.group-name,Values=$OVERVIEW_ENVIRONMENT-$1" \
      "Name=instance-state-name,Values=pending,running" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text
}

# Creates a temporary file that holds a cloud-init config.
#
# Arguments:
#   $1: SERVER, one of "web", "worker", "database" and "searchindex"
#
# The temporary file is created from cloud-init/$SERVER, and all instances of
# OVERVIEW_ENVIRONMENT# and #OVERVIEW_ENVIRONMENT_ADDRESS# within it are
# replaced with, say, "staging" and "staging.overviewproject.org".
generate_cloud_init_file() {
  ret=$(mktemp launch-overview-XXXXXX)
  cat "$DIR"/../cloud-init/$1.txt \
    | sed -e "s/#OVERVIEW_ENVIRONMENT#/$OVERVIEW_ENVIRONMENT/" \
    | sed -e "s/#OVERVIEW_ENVIRONMENT_ADDRESS#/$OVERVIEW_HOSTNAME/" \
    > "$ret"

  echo $ret
}

run_staging_database() {
  init_file=$(generate_cloud_init_file database)
  snapshot_id=$(get_database_snapshot_id)
  aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type m3.large \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=$OVERVIEW_ENVIRONMENT-database \
    --security-groups $OVERVIEW_ENVIRONMENT-database \
    --user-data "file://$init_file" \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"SnapshotId\":\"$snapshot_id\",\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\"}}]" \
    | grep 'InstanceId' | cut -d'"' -f4
  rm $init_file
}

run_production_database() {
  init_file=$(generate_cloud_init_file database)
  volume_id=$(get_volume_id 'production-database')

  # Start the instance without its volume.
  instance_id=$(aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type m3.large \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=$OVERVIEW_ENVIRONMENT-database \
    --security-groups $OVERVIEW_ENVIRONMENT-database \
    --user-data "file://$init_file" \
    | grep 'InstanceId' | cut -d'"' -f4)
  rm $init_file

  # Attach the volume. There's a race here, but we should be fine.
  sleep 1
  aws ec2 attach-volume \
    --volume-id $volume_id \
    --instance-id $instance_id \
    --device 'xvdf' \
    >/dev/null

  echo $instance_id
}

run_database() {
  if [ 'staging' = "$OVERVIEW_ENVIRONMENT" ]; then
    run_staging_database
  else
    run_production_database
  fi
}

run_staging_searchindex() {
  init_file=$(generate_cloud_init_file searchindex)
  snapshot_id=$(get_searchindex_snapshot_id)
  aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type m3.large \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=$OVERVIEW_ENVIRONMENT-searchindex \
    --security-groups $OVERVIEW_ENVIRONMENT-searchindex \
    --user-data "file://$init_file" \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"SnapshotId\":\"$snapshot_id\",\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\"}}]" \
    | grep 'InstanceId' | cut -d'"' -f4
  rm $init_file
}

run_production_searchindex() {
  init_file=$(generate_cloud_init_file searchindex)
  volume_id=$(get_volume_id "production-searchindex")

  # Start the instance without its volume
  instance_id=$(aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type m3.large \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=$OVERVIEW_ENVIRONMENT-searchindex \
    --security-groups $OVERVIEW_ENVIRONMENT-searchindex \
    --user-data "file://$init_file" \
    | grep 'InstanceId' | cut -d'"' -f4)
  rm $init_file

  # Attach the volume. There's a race here, but we should be fine.
  sleep 1
  aws ec2 attach-volume \
    --volume-id $volume_id \
    --instance-id $instance_id \
    --device 'xvdf' \
    >/dev/null

  echo $instance_id
}

run_searchindex() {
  if [ 'staging' = "$OVERVIEW_ENVIRONMENT" ]; then
    run_staging_searchindex
  else
    run_production_searchindex
  fi
}

run_worker() {
  init_file=$(generate_cloud_init_file worker)
  aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type m3.medium \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=$OVERVIEW_ENVIRONMENT-worker \
    --security-groups $OVERVIEW_ENVIRONMENT-worker \
    --user-data "file://$init_file" \
    | grep 'InstanceId' | cut -d'"' -f4
  rm $init_file
}

run_web() {
  init_file=$(generate_cloud_init_file web)
  aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type m3.medium \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=$OVERVIEW_ENVIRONMENT-web \
    --security-groups $OVERVIEW_ENVIRONMENT-web \
    --user-data "file://$init_file" \
    | grep 'InstanceId' | cut -d'"' -f4
  rm $init_file
}

# Returns an instance ID
ec2_run_instance() {
  case $1 in
    database)
      run_database
      ;;
    searchindex)
      run_searchindex
      ;;
    worker)
      run_worker
      ;;
    web)
      run_web
      ;;
    *)
      fatal "Invalid instance type '$1'"
      ;;
  esac
}

start_instance() {
  instance_type=$1
  instance_id=$(get_instance_id $1)
  if [ -z "$instance_id" ]; then
    >&2 echo "Launching $instance_type instance"
    instance_id=$(ec2_run_instance $1)
    aws ec2 create-tags \
      --resources $instance_id \
      --tags \
        "Key=Name,Value=$OVERVIEW_ENVIRONMENT-$instance_type" \
        "Key=Environment,Value=$OVERVIEW_ENVIRONMENT" \
        >/dev/null
    >&2 echo "Launched $instance_type instance $instance_id"

    instance_ip=$(wait_for_instance_ip $instance_id)
    >&2 echo "Instance $instance_id has IP address $instance_ip"

    if [ 'web' = "$instance_type" ]; then
      public_ip=$(dig +short $OVERVIEW_HOSTNAME)
      >&2 aws ec2 associate-address \
        --instance-id $instance_id \
        --public-ip $public_ip \
        >/dev/null
      >&2 echo "Instance $instance_id associated with public IP $public_ip"
    fi

    >&2 overview-manage add-instance $OVERVIEW_ENVIRONMENT/$instance_type/$instance_ip
  else
    >&2 echo "There was already a $instance_type instance"
  fi
  echo $instance_id
}

instance_types=(database searchindex worker web)
instance_ids=()
for instance_type in ${instance_types[@]}; do
  >&2 echo "Ensuring $instance_type is launched..."
  instance_id=$(start_instance $instance_type)
  instance_ids+=($instance_id)
done

for instance_id in ${instance_ids[@]}; do
  >&2 echo "Ensuring $instance_id is finished initializing..."
  instance_ip=$(wait_for_instance_ip $instance_id)
  wait_for_ssh $instance_ip
  wait_for_cloud_init $instance_ip
done

>&2 echo "Up and running"
