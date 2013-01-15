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

We start up a vanilla Ubuntu, add some packages, and create an AMI from the result.

## How we create instances

We fire up each instance with the proper AMI, instance type, availability zone and security group.

## How we maintain instances

We run Ubuntu updates.

## Method naming

A method ending in `!` may cost (or save) money (for instance, by creating new EC2 instances). Any method without a `!` probably won't affect your balance sheet.
