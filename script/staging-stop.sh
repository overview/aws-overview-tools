#!/bin/bash

# Terminates all the staging instances and removes them from overview-manage's
# memory.

fatal() {
  echo "$1"
  exit 1
}

wait_for_volume_to_detach() {
  while [ '0' != $(aws ec2 describe-volumes --volume-id $1 | grep -c '"detaching"') ]; do
    echo "$1 is still detaching; will try again in 1s"
    sleep 1
  done
}

detach_volume() {
  # Works even when the volume is already detached by iterating over the list
  # of 0 or 1 volumes that were detached
  if [ '0' == $(aws ec2 describe-volumes --volume-id $1 | grep -Ec 'State.*(attached|in-use)' | cut -d'"' -f4) ]; then
    echo "Detaching volume $volume_id..."
    aws ec2 detach-volume --volume-id $1 --force
    wait_for_volume_to_detach $volume_id
  else
    echo "Volume $volume_id is already detached"
  fi
}

delete_volume() {
  detach_volume $1
  aws ec2 delete-volume --volume-id $1 > /dev/null
}

: ${AWS_ACCESS_KEY_ID:?'You must set the AWS_ACCESS_KEY_ID environment variable'}
: ${AWS_SECRET_ACCESS_KEY:?'You must set the AWS_SECRET_ACCESS_KEY environment variable'}
: ${AWS_DEFAULT_REGION:?'You must set the AWS_DEFAULT_REGION environment variable'}
type -p aws >/dev/null || fatal 'You need the `aws` command in your $PATH'
type -p ssh >/dev/null || fatal 'You need the `ssh` command in your $PATH'

instance_ids=$(aws ec2 describe-instances --filter Name=instance.group-name,Values=database-staging,web-staging,searchindex-staging,worker-staging | grep InstanceId | cut -d'"' -f4 | xargs)

if [ -z "$instance_ids" ]; then
  echo 'Not terminating any staging instances: there are none'
else
  echo "Terminating instances: $instance_ids"
  aws ec2 terminate-instances --instance-ids $instance_ids >/dev/null
fi

volume_ids=$(aws ec2 describe-volumes --filter 'Name=tag:Name,Values=staging-apollo,staging-searchindex,staging-database' | grep VolumeId | cut -d'"' -f4 | xargs)

if [ -z "$volume_ids" ]; then
  echo 'Not deleting any volumes: there are none'
else
  echo "Deleting volumes: $volume_ids"
  for volume_id in $volume_ids; do
    delete_volume $volume_id
  done
fi

manage_host=$(aws ec2 describe-instances --filter 'Name=tag:Name,Values=manage' | grep PublicDnsName | cut -d'"' -f4)

if [ -z "$manage_host" ]; then
  echo 'Could not find the manage instance'
  exit 1
else
  echo "Connecting to $manage_host to disable staging"
  ssh ubuntu@"$manage_host" 'for instance in $(overview-manage status | grep staging | cut -f2,3,4 | sed -e '"'"'s/\t/\//g'"'"'); do overview-manage remove-instance $instance; done'
fi
