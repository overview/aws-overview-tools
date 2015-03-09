#!/bin/bash

# Creates volumes and starts up staging instances.

fatal() {
  >&2 echo "$1"
  exit 1
}

: ${AWS_ACCESS_KEY_ID:?'You must set the AWS_ACCESS_KEY_ID environment variable'}
: ${AWS_SECRET_ACCESS_KEY:?'You must set the AWS_SECRET_ACCESS_KEY environment variable'}
: ${AWS_DEFAULT_REGION:?'You must set the AWS_DEFAULT_REGION environment variable'}
: ${OVERVIEW_MANAGE_HOST:?'You must set the OVERVIEW_MANAGE_HOST environment variables'}
type -p aws >/dev/null || fatal 'You need the `aws` command in your $PATH'
type -p ssh >/dev/null || fatal 'You need the `ssh` command in your $PATH'

DIR="$(dirname $0)"
AVAILABILITY_ZONE=us-east-1a
BASE_IMAGE=ami-f0693098 # https://cloud-images.ubuntu.com/utopic/current/ us-east-1 64-bit hvm

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
      "Name=instance.group-name,Values=staging-$1" \
      "Name=instance-state-name,Values=pending,running" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text
}

# Creates a temporary file that holds a cloud-init config.
#
# Arguments:
#   $1: SERVER, one of "web", "worker", "database" and "searchindex"
#   $2: OVERVIEW_ENVIRONMENT, either "staging" or "production"
#   $3: OVERVIEW_ENVIRONMENT_ADDRESS, either "staging.overviewproject.org" or "www.overviewproject.org"
#
# The temporary file is created from cloud-init/$SERVER, and all instances of
# OVERVIEW_ENVIRONMENT# and #OVERVIEW_ENVIRONMENT_ADDRESS# within it are
# replaced with $2 and $3.
generate_cloud_init_file() {
  ret=$(tempfile)
  cat "$DIR"/../cloud-init/$1.txt \
    | sed -e "s/#OVERVIEW_ENVIRONMENT#/$2/" \
    | sed -e "s/#OVERVIEW_ENVIRONMENT_ADDRESS#/$3/" \
    > "$ret"

  echo $ret
}

run_database() {
  init_file=$(generate_cloud_init_file database staging)
  snapshot_id=$(get_database_snapshot_id)
  aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type m3.large \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=staging-database \
    --security-groups staging-database \
    --user-data "file://$init_file" \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"SnapshotId\":\"$snapshot_id\",\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\"}}]" \
    | grep 'InstanceId' | cut -d'"' -f4
  rm $init_file
}

run_searchindex() {
  init_file=$(generate_cloud_init_file searchindex staging)
  snapshot_id=$(get_searchindex_snapshot_id)
  aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type c4.large \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=staging-searchindex \
    --security-groups staging-searchindex \
    --user-data "file://$init_file" \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"SnapshotId\":\"$snapshot_id\",\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\"}}]" \
    | grep 'InstanceId' | cut -d'"' -f4
  rm $init_file
}

run_worker() {
  init_file=$(generate_cloud_init_file worker staging)
  aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type m3.medium \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=staging-worker \
    --security-groups staging-worker \
    --user-data "file://$init_file" \
    | grep 'InstanceId' | cut -d'"' -f4
  rm $init_file
}

run_web() {
  init_file=$(generate_cloud_init_file web staging staging.overviewproject.org)
  aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type m3.medium \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name manage \
    --iam-instance-profile Name=staging-web \
    --security-groups staging-web \
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
        "Key=Name,Value=staging-$instance_type" \
        "Key=Environment,Value=staging" \
        >/dev/null
    >&2 echo "Launched $instance_type instance $instance_id"

    instance_ip=$(wait_for_instance_ip $instance_id)
    >&2 echo "Instance $instance_id has IP address $instance_ip"

    if [ 'web' = "$instance_type" ]; then
      public_ip=$(dig +short staging.overviewproject.org)
      >&2 aws ec2 associate-address \
        --instance-id $instance_id \
        --public-ip $public_ip \
        >/dev/null
      >&2 echo "Instance $instance_id associated with public IP $public_ip"
    fi

    >&2 overview-manage add-instance staging/$instance_type/$instance_ip
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
