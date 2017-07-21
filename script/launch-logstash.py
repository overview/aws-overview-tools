#!/usr/bin/env python3

import botocore.exceptions
import boto3
import logging
import os

boto3.set_stream_logger(level=logging.INFO)

Constants = {
    'ImageId': 'ami-a60c23b0',
    'InstanceType': 't2.small',
    'VpcCidr': '10.0.0.0/16',
    'SubnetCidr': '10.0.0.0/24',
}

IAM = boto3.resource('iam')
EC2Client = boto3.client('ec2')
EC2Resource = boto3.resource('ec2')

def lookup_vpc():
    """Returns: the VPC Resource."""
    response = EC2Client.describe_vpcs(Filters=[
        { 'Name': 'cidr', 'Values': [ Constants['VpcCidr'] ] },
    ])

    if len(response['Vpcs']) != 1:
        raise Exception("Did not find a VPC for " + Constants['VpcCidr'])

    vpc_id = response['Vpcs'][0]['VpcId']
    vpc = EC2Resource.Vpc(vpc_id)

    return vpc

def lookup_subnet(vpc):
    """Returns: the Subnet Resource."""
    response = EC2Client.describe_subnets(Filters=[
        { 'Name': 'vpc-id', 'Values': [ vpc.id ] },
        { 'Name': 'cidrBlock', 'Values': [ Constants['SubnetCidr'] ] },
    ])

    if len(response['Subnets']) != 1:
        raise Exception("Did not find a Subnet for " + Constants['SubnetCidr'])

    subnet_id = response['Subnets'][0]['SubnetId']
    subnet = EC2Resource.Subnet(subnet_id)

    return subnet

def ensure_security_group_created(vpc):
    """Creates the Logstash security group.

    It allows syslog-RELP access from all machines in the VPC.

    Returns: a SecurityGroup resource.
    """
    existing = list(vpc.security_groups.filter(Filters=[
        { 'Name': 'group-name', 'Values': [ 'logstash' ] }
    ]))

    if len(existing) == 0:
        ret = vpc.create_security_group(
            GroupName='logstash',
            Description='logstash'
        )
    else:
        ret = existing[0]

    try:
        ret.authorize_ingress(IpPermissions=[
            { 'IpProtocol': 'tcp', 'FromPort': 2514, 'ToPort': 2514, 'IpRanges': [ { 'CidrIp': Constants['VpcCidr'] } ] },
        ])
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] != 'InvalidPermission.Duplicate':
            raise e

    return ret

def ensure_instance_role_created():
    """Ensures you can start an instance with the AWS permissions it needs.

    Returns: an IAM Role resource.
    """
    # TODO actually implement this
    return IAM.Role("logstash")

def ensure_logstash_created(subnet, security_group, role):
    """Returns: an EC2Instance resource.
    """
    instances = list(subnet.instances.filter(Filters=[{
        'Name': 'tag:Name',
        'Values': [ 'logstash' ],
    }, {
        'Name': 'instance-state-name',
        'Values': [ 'pending', 'running' ],
    }]))

    if len(instances) > 0:
        instance = instances[0]
    else:
        path = os.path.dirname(__file__) + '/../cloud-init/logstash.txt'
        with open(path, 'rt') as f:
            cloud_init_string = f.read()

        instances = subnet.create_instances(
            ImageId=Constants['ImageId'],
            MinCount=1,
            MaxCount=1,
            KeyName=os.environ['AWS_KEYPAIR_NAME'],
            SecurityGroupIds=[ security_group.id ],
            UserData=cloud_init_string,
            InstanceType=Constants['InstanceType'],
            EbsOptimized=False,
            IamInstanceProfile={ 'Name': role.name },
            TagSpecifications=[
                {
                    'ResourceType': 'instance',
                    'Tags': [
                        { 'Key': 'Name', 'Value': 'logstash' },
                        { 'Key': 'Environment', 'Value': 'logstash' },
                    ],
                },
                {
                    'ResourceType': 'volume',
                    'Tags': [
                        { 'Key': 'Name', 'Value': 'logstash' },
                        { 'Key': 'Environment', 'Value': 'logstash' },
                    ],
                },
            ]
        )

        instance = instances[0]

    instance.wait_until_running()

    return instances[0]

vpc = lookup_vpc()
subnet = lookup_subnet(vpc)
security_group = ensure_security_group_created(vpc)
role = ensure_instance_role_created()
instance = ensure_logstash_created(subnet, security_group, role)
