#!/usr/bin/env python3

# Terminates all the staging instances and removes them from overview-manage's
# memory.

import boto3
import logging
import os

boto3.set_stream_logger(level=logging.INFO)

EC2Client = boto3.client('ec2')
EC2Resource = boto3.resource('ec2')
ELB = boto3.client('elbv2')

def terminate_instances(environment):
    """Terminates all 'conglomerate' instances in the environment.
    """
    instances = list(EC2Resource.instances.filter(Filters=[{
        'Name': 'tag:Name',
        'Values': [ 'staging-conglomerate' ],
    }]))
    instance_ids = [ instance.instance_id for instance in instances ]
    EC2Client.terminate_instances(InstanceIds=instance_ids)

def terminate_load_balancers(environment):
    """Terminates all load balancers in the environment.
    """
    response = ELB.describe_load_balancers(Names=[ environment + '-load-balancer' ])
    for load_balancer in response['LoadBalancers']:
        ELB.delete_load_balancer(LoadBalancerArn=load_balancer['LoadBalancerArn'])

environment = 'staging'
terminate_instances(environment)
terminate_load_balancers(environment)
