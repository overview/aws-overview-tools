#!/usr/bin/env python3

import botocore.exceptions
import boto3
import logging
import os

boto3.set_stream_logger(level=logging.INFO)

Constants = {
    # Overview stuff
    'ImageId': 'ami-dfcab0b5',
    'InstanceType': 'r3.xlarge',
    'DatabaseVolumeGb': '500',
    'SearchindexVolumeGb': '300',

    # VPC and subnet where our instances go
    'VpcName': 'overview',
    'VpcCidr': '10.0.0.0/16',
    'SubnetName': 'overview',
    'SubnetCidr': '10.0.0.0/24',
    'SubnetAvailabilityZone': 'us-east-1a',

    # DNS stuff on Route 53
    'HostedZoneId': 'Z372XVIFF1FHQW',
    'DnsNames': {
        'production': [ 'www.overviewdocs.com', 'overviewdocs.com' ],
        'staging': [ 'staging.overviewdocs.com', 'staging-redirect.overviewdocs.com' ],
    },

    # ELB requires at least two availability zones, so we'll create a second one
    'Subnet2Name': 'overview2',
    'Subnet2Cidr': '10.0.1.0/24',
    'Subnet2AvailabilityZone': 'us-east-1e',

    # ELB stuff
    'SslCertificateName': { 'production': 'www.overviewdocs.com', 'staging': 'staging.overviewdocs.com' },
}

ACM = boto3.client('acm')
S3 = boto3.client('s3')
EC2Client = boto3.client('ec2')
EC2Resource = boto3.resource('ec2')
ELB = boto3.client('elbv2')
IAM = boto3.resource('iam')
Route53 = boto3.client('route53')

def read_cloud_init_string(environment):
    """Builds a cloud-init string for a Conglomerate instance.
    """
    logstash_instances = list(EC2Resource.instances.filter(Filters=[{
        'Name': 'tag:Name',
        'Values': [ 'logstash' ],
    }]))
    if len(logstash_instances) == 0:
        raise Exception('You need to create a "logstash" instance before running this script. Aborted.')
    logstash_ip = logstash_instances[0].private_ip_address

    path = os.path.dirname(__file__) + '/../cloud-init/conglomerate.txt'
    with open(path, 'rt') as f:
        s = f.read()
        s = s.replace('#OVERVIEW_ENVIRONMENT#', environment)
        s = s.replace('#LOGSTASH_IP#', logstash_ip)
        return s

def ensure_vpc_created():
    """Creates the Overview VPC, if it is not already there

    Returns: the VPC Resource.
    """
    response = EC2Client.describe_vpcs(Filters=[
        { 'Name': 'cidr', 'Values': [ Constants['VpcCidr'] ] },
    ])

    if len(response['Vpcs']) != 1:
        # untested
        vpc = EC2Resource.create_vpc(
                CidrBlock=Constants['VpcCidr'],
                AmazonProvidedIpv6CidrBlock=True
        )
    else:
        # usual case: VPC already exists
        vpc_id = response['Vpcs'][0]['VpcId']
        vpc = EC2Resource.Vpc(vpc_id)

    vpc.create_tags(Tags=[
        { 'Key': 'Name', 'Value': Constants['VpcName'] },
    ])

    vpc.wait_until_available()

    return vpc

def _ensure_subnet_created(vpc, availability_zone, name, cidr, cidr6_end_digits):
    response = EC2Client.describe_subnets(Filters=[
        { 'Name': 'vpc-id', 'Values': [ vpc.id ] },
        { 'Name': 'cidrBlock', 'Values': [ cidr ] },
    ])

    if len(response['Subnets']) != 1:
        # untested
        subnet = vpc.create_subnet(
            VpcId=vpc.id,
            CidrBlock=cidr,
            Ipv6CidrBlock=vpc.ipv6_cidr_block_association_set[0]['Ipv6CidrBlock'].replace('00::/56', cidr6_end_digits + '::/64'),
            AvailabilityZone=availability_zone
        )
    else:
        # usual case: Subnet already exists
        subnet_id = response['Subnets'][0]['SubnetId']
        subnet = EC2Resource.Subnet(subnet_id)

    subnet.create_tags(Tags=[
        { 'Key': 'Name', 'Value': name },
    ])

    return subnet

def ensure_subnet_created(vpc):
    """Creates the Overview subnet, if it is not already there.

    Returns: the Subnet resource.
    """
    return _ensure_subnet_created(
        vpc,
        Constants['SubnetAvailabilityZone'],
        Constants['SubnetName'],
        Constants['SubnetCidr'],
        '00'
    )

def ensure_subnet2_created(vpc):
    return _ensure_subnet_created(
        vpc,
        Constants['Subnet2AvailabilityZone'],
        Constants['Subnet2Name'],
        Constants['Subnet2Cidr'],
        '01'
    )

def ensure_security_groups_created(vpc, environment):
    """Creates all security groups Overview needs, and sets their rules.

    The security groups we create in the "production" environment:
    * production-conglomerate: Conglomerate instance
    * production-load-balancer: Load balancer

    Returns: a dict mapping name (e.g., "load-balancer") to SecurityGroup resource.
    """
    conglomerate_name = environment + '-conglomerate'
    load_balancer_name = environment + '-load-balancer'

    existing = vpc.security_groups.filter(Filters=[
        { 'Name': 'group-name', 'Values': [ conglomerate_name, load_balancer_name ] }
    ])
    ret = {}
    for security_group in existing:
        if security_group.group_name == conglomerate_name:
            ret['conglomerate'] = security_group
        elif security_group.group_name == load_balancer_name:
            ret['load-balancer'] = security_group
        else:
            raise Exception("Unexpected security group name: " + security_group.group_name)

    if not ret['conglomerate']:
        # untested
        ret['conglomerate'] = vpc.create_security_group(
            GroupName=conglomerate_name,
            Description=conglomerate_name
        )
    if not ret['load-balancer']:
        # untested
        ret['load-balancer'] = vpc.create_security_group(
            GroupName=load_balancer_name,
            Description=load_balancer_name
        )

    try:
        ret['conglomerate'].authorize_ingress(IpPermissions=[
            { 'IpProtocol': 'icmp', 'FromPort': 0, 'ToPort': 255, 'IpRanges': [ { 'CidrIp': '0.0.0.0/0' } ] },
            { 'IpProtocol': 'tcp', 'FromPort': 9000, 'ToPort': 9000, 'UserIdGroupPairs': [ { 'GroupId': ret['load-balancer'].id } ] },
        ])
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] != 'InvalidPermission.Duplicate':
            raise e

    try:
        ret['load-balancer'].authorize_ingress(IpPermissions=[
            { 'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80 },
            { 'IpProtocol': 'tcp', 'FromPort': 443, 'ToPort': 443 },
            { 'IpProtocol': 'icmp', 'FromPort': 0, 'ToPort': 255, 'IpRanges': [ { 'CidrIp': '0.0.0.0/0' } ] },
            { 'IpProtocol': 'tcp', 'FromPort': 1024, 'ToPort': 65535, 'IpRanges': [ { 'CidrIp': Constants['VpcCidr'] } ] },
        ])
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] != 'InvalidPermission.Duplicate':
            raise e

    return ret

def ensure_instance_role_created(environment):
    """Ensures you can start an instance with the AWS permissions it needs.

    Currently, Overview needs to read the "secrets" buckets and read/write the
    blob-storage buckets. That means that by the time this method returns, all
    the buckets must exist.

    Returns: an IAM Role resource.
    """
    # TODO actually implement this
    return IAM.Role(environment + '-conglomerate')

def ensure_ips_created():
    pass

def ensure_secrets_created():
    pass

def ensure_target_group_created(vpc, environment):
    """Ensures your load balancer can point somewhere.

    Returns: an ELBv2 TargetGroup ARN.
    """
    name = environment + '-web'

    # If it already exists, create returns the existing data
    response = ELB.create_target_group(
        Name=name,
        Protocol='HTTP',
        Port=9000,
        VpcId=vpc.id,
        Matcher={
            'HttpCode': '200,301'
        }
    )

    arn = response['TargetGroups'][0]['TargetGroupArn']

    return arn

def get_ssl_certificate_arn(environment):
    """Loads an SSL certificate ARN for the given environment.
    """
    name = Constants['SslCertificateName'][environment]

    certificates = ACM.list_certificates(CertificateStatuses=[ 'ISSUED' ])['CertificateSummaryList']
    arns = [ c['CertificateArn'] for c in certificates if c['DomainName'] == name ]

    if len(arns) == 0:
        raise Exception('Missing certificate %s on AWS. Please create it and then re-run this script.' % name)

    return arns[0]

def ensure_load_balancer_created(vpc, security_group, subnet1, subnet2, target_group_arn, ssl_certificate_arn, environment):
    """Creates the load balancer, if it does not already exist.

    Returns: an ELBv2 LoadBalancer dict.
    """
    name = environment + '-load-balancer'

    # If it already exists, create returns the existing data
    response = ELB.create_load_balancer(
        Name=name,
        Subnets=[ subnet1.id, subnet2.id ],
        SecurityGroups=[ security_group.id ],
        IpAddressType='dualstack',
        Tags=[
            { 'Key': 'Name', 'Value': name },
            { 'Key': 'Environment', 'Value': environment }
        ]
    )

    load_balancer = response['LoadBalancers'][0]
    arn = load_balancer['LoadBalancerArn']

    # There seems to be no harm in creating listeners if they already exist
    ELB.create_listener(
        LoadBalancerArn=arn,
        Protocol='HTTP',
        Port=80,
        DefaultActions=[{ 'Type': 'forward', 'TargetGroupArn': target_group_arn } ]
    )

    ELB.create_listener(
        LoadBalancerArn=arn,
        Protocol='HTTPS',
        Port=443,
        SslPolicy='ELBSecurityPolicy-TLS-1-2-2017-01',
        Certificates=[ { 'CertificateArn': ssl_certificate_arn } ],
        DefaultActions=[ { 'Type': 'forward', 'TargetGroupArn': target_group_arn } ]
    )

    return load_balancer

def ensure_dns_records_point_to_load_balancer(load_balancer, environment):
    """Makes sure the DNS records for the given environment point to the given
    load balancer.
    """
    zone_id = Constants['HostedZoneId']
    dns_names = Constants['DnsNames'][environment]

    # sum() -- takes a list of lists and outputs a single list :)
    changes = sum([ [
        {
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': dns_name,
                'Type': 'A',
                'AliasTarget': {
                    'HostedZoneId': load_balancer['CanonicalHostedZoneId'],
                    'DNSName': load_balancer['DNSName'],
                    'EvaluateTargetHealth': False,
                },
            },
        },
        {
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': dns_name,
                'Type': 'AAAA',
                'AliasTarget': {
                    'HostedZoneId': load_balancer['CanonicalHostedZoneId'],
                    'DNSName': load_balancer['DNSName'],
                    'EvaluateTargetHealth': False,
                },
            },
        },
    ] for dns_name in dns_names ], [])

    Route53.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch={
            'Comment': 'Auto-updated by launch-conglomerate.py',
            'Changes': changes,
        }
    )

def ensure_volume_exists(name, size, availability_zone, environment):
    '''Returns an existing EC2 Volume resource, or creates a new one if needed.
    '''
    existing_volumes = EC2Resource.filter_volumes.filter(Filters=[{
        'Name': 'tag:Name',
        'Values': [ name ],
    }])

    if len(existing_volumes) > 0:
        volume = existing_volumes[0]
    else:
        volume = EC2Resource.create_volume(
            Size=size,
            AvailabilityZone=availability_zone,
            VolumeType='gp2',
            TagSpecifications=[
                {
                    'ResourceType': 'volume',
                    'Tags': [
                        { 'Key': 'Name', 'Value': name },
                        { 'Key': 'Environment', 'Value': environment },
                    ],
                }
            ]
        )

    volume

def ensure_conglomerate_created(subnet, security_group, role, environment):
    name = environment + '-conglomerate'

    instances = list(subnet.instances.filter(Filters=[{
        'Name': 'tag:Name',
        'Values': [ name ],
    }]))

    if len(instances) > 0:
        instance = instances[0]
    else:
        # set block_device_mappings.
        # On staging, we'll auto-create volumes from snapshots. On production,
        # we'll mount volumes that we try to find.
        if environment == 'staging':
            database_snapshots = list(EC2Resource.snapshots.filter(Filters=[{
                'Name': 'description',
                'Values': [ '[database] Daily backup' ],
            }]))
            if len(database_snapshots) == 0:
                raise Exception('There is no daily Database backup, so we cannot launch staging')
            database_snapshot = database_snapshots[0]

            searchindex_snapshots = list(EC2Resource.snapshots.filter(Filters=[{
                'Name': 'description',
                'Values': [ '[searchindex] Daily backup' ],
            }]))
            if len(searchindex_snapshots) == 0:
                raise Exception('There is no daily Searchindex backup, so we cannot launch staging')
            searchindex_snapshot = searchindex_snapshots[0]

            block_device_mappings = [
                {
                    'DeviceName': '/dev/sdf',
                    'Ebs': {
                        'SnapshotId': database_snapshot.id,
                        'DeleteOnTermination': True,
                        'VolumeType': 'gp2',
                    },
                },
                {
                    'DeviceName': '/dev/sdg',
                    'Ebs': {
                        'SnapshotId': searchindex_snapshot.id,
                        'DeleteOnTermination': True,
                        'VolumeType': 'gp2',
                    },
                },
                {
                    # When we migrate to a more modern EC2 instance
                    # type we won't be able to use this any more.
                    'DeviceName': '/dev/sdb',
                    'VirtualName': 'ephemeral0',
                },
            ]
        else:
            block_device_mappings = [
                {
                    # When we migrate to a more modern EC2 instance
                    # type we won't be able to use this any more.
                    'DeviceName': '/dev/sdb',
                    'VirtualName': 'ephemeral0',
                },
            ]

        instances = subnet.create_instances(
            ImageId=Constants['ImageId'],
            MinCount=1,
            MaxCount=1,
            KeyName=os.environ['AWS_KEYPAIR_NAME'],
            SecurityGroupIds=[ security_group.id ],
            UserData=read_cloud_init_string(environment),
            InstanceType=Constants['InstanceType'],
            BlockDeviceMappings=block_device_mappings,
            EbsOptimized=False,
            IamInstanceProfile={ 'Name': role.name },
            TagSpecifications=[
                {
                    'ResourceType': 'instance',
                    'Tags': [
                        { 'Key': 'Name', 'Value': environment + '-conglomerate' },
                        { 'Key': 'Environment', 'Value': environment },
                    ],
                },
                {
                    'ResourceType': 'volume',
                    'Tags': [
                        { 'Key': 'Name', 'Value': environment + '-conglomerate' },
                        { 'Key': 'Environment', 'Value': environment },
                    ],
                },
            ]
        )

        instance = instances[0]

        if environment == 'production':
            # Attach production volumes after we launch the instance but
            # before the OS boots up and tries to mount them. There's a race
            # here -- hope that the volumes are attached before the init script
            # looks for them. (It spends a long time with a dist-upgrade, so
            # we're probably okay.)
            database_volume = ensure_volume_exists(
                'production-database',
                Constants['DatabaseVolumeGb'],
                subnet.availability_zone,
                environment
            )
            searchindex_volume = ensure_volume_exists(
                'production-searchindex',
                Constants['SearchindexVolumeGb'],
                subnet.availability_zone,
                environment
            )

            instance.wait_until_running()

            instance.attach_volume(VolumeId=database_volume.id, Device='/dev/sdf')
            instance.attach_volume(VolumeId=searchindex_volume_id, Device='/dev/sdg')

    instance.wait_until_running()

    return instances[0]

def ensure_conglomerate_added_to_target_group(instance, target_group_arn):
    '''Point target group to the given instance, if it wasn't pointed already.
    '''
    ELB.register_targets(
        TargetGroupArn=target_group_arn,
        Targets=[
            { 'Id': instance.id },
        ]
    )

environment = 'staging'
vpc = ensure_vpc_created()
subnet = ensure_subnet_created(vpc)
subnet2 = ensure_subnet2_created(vpc)
security_groups = ensure_security_groups_created(vpc, environment)
role = ensure_instance_role_created(environment)
target_group_arn = ensure_target_group_created(vpc, environment)
ssl_certificate_arn = get_ssl_certificate_arn(environment)
load_balancer = ensure_load_balancer_created(
    vpc, security_groups['load-balancer'], subnet, subnet2,
    target_group_arn, ssl_certificate_arn, environment
)
ensure_dns_records_point_to_load_balancer(load_balancer, environment)
instance = ensure_conglomerate_created(subnet, security_groups['conglomerate'], role, environment)
ensure_conglomerate_added_to_target_group(instance, target_group_arn)
