# Instances

Under this directory are all the scripts and configuration files we use to create AMI images.

## Amazon AWS Configurations

We have the following instances:

1. `database`: database server
2. `database-backup`: a hot copy of the database
3. `worker`: worker
4. `web`: web server
5. `database-staging`: staging database
6. `worker-staging`: staging worker
7. `web-staging`: staging web server
8. `manage`: the instance we use to maintain other instances

We maintain the following volumes, which must be present for the corresponding machines to run:

1. `database`: Postgres database
2. `database-staging`
3. `database-backup`: in a separate availability zone

We tag instances, volumes, and AMI images with a `Type`. For instance, filter by tag `Type = worker` to find all worker instances.

There can only be one AMI image or volume with a given type, but there may be multiple instances.

## How we create AMIs

We follow the guidelines at http://alestic.com/2010/01/ec2-ebs-boot-ubuntu

Basically, we log into the "manage" machine and build other instances while there.

For each instance type, we have three forms of customization:

1. We decide upon an AWS instance type, security group, volumes, et cetera;
2. We decide which packages to install; and
3. We copy certain configuration files

There's a clear "hierarchy" for both customizations: `database-staging` looks a lot like `database` but with a couple of different IP addresses, for instance.

This logic is all coded in Ruby 1.8, because that's a dependency for EC2-management tools anyway.

## Method naming

A method ending in `!` may cost (or save) money (for instance, by creating new EC2 instances). Any method without a `!` probably won't affect your balance sheet.
