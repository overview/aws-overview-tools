# Using this package

This tool does two things:

* It creates Amazon Machine Images (AMIs). Each AMI represents a server configuration: we may spin up multiple instances of each server configuration.
* It spins up AMIs into new Instances. Each Instance is a server: a virtual machine.

Here's how to use it:

1. Create all the amazon machine images (only do this once!):
    1. `export AWS_CREDENTIAL_FILE=[your credentials] AWS_ACCESS_KEY_ID=[whatever] AWS_SECRET_ACCESS_KEY=[whatever] && ./build_images.rb` ([find your keypair](https://console.aws.amazon.com/ec2/v2/home#KeyPairs:)) ([find your access key](https://console.aws.amazon.com/iam/home#users) and [read more about credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-installing-credentials))
    1. Log into AWS and delete all the running instances. (You may test them before turning them off, but they're costing money.)

1. Spin up an instance
    1. `./create_instance.rb TYPE ZONE` -- see `create_instance.rb`'s comments

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
