#!/bin/bash

# Terminates all the staging instances and removes them from overview-manage's
# memory.

fatal() {
  echo "$1"
  exit 1
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

manage_host=$(aws ec2 describe-instances --filter 'Name=tag:Name,Values=manage' | grep PublicDnsName | cut -d'"' -f4)

if [ -z "$manage_host" ]; then
  echo 'Could not find the manage instance'
  exit 1
else
  echo "Connecting to $manage_host to disable staging"
  ssh ubuntu@"$manage_host" 'for instance in $(overview-manage status | grep staging | cut -f2,3,4 | sed -e '"'"'s/\t/\//g'"'"'); do overview-manage remove-instance $instance; done'
fi
