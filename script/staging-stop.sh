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
: ${OVERVIEW_MANAGE_HOST:?'You must set the OVERVIEW_MANAGE_HOST environment variable to ubuntu@[ip address]'}
type -p aws >/dev/null || fatal 'You need the `aws` command in your $PATH'
type -p ssh >/dev/null || fatal 'You need the `ssh` command in your $PATH'

instance_ids=$(aws ec2 describe-instances --filter Name=tag:Environment,Values=staging | grep InstanceId | cut -d'"' -f4 | xargs)

if [ -z "$instance_ids" ]; then
  echo 'Not terminating any staging instances: there are none'
else
  echo "Terminating instances: $instance_ids"
  aws ec2 terminate-instances --instance-ids $instance_ids >/dev/null
fi

echo "Connecting to $OVERVIEW_MANAGE_HOST to disable staging"
ssh "$OVERVIEW_MANAGE_HOST" 'for instance in $(overview-manage status | grep staging | cut -f2,3,4 | sed -e '"'"'s/\t/\//g'"'"'); do overview-manage remove-instance $instance; done'
