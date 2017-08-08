The `manage` program: turning Overview from code to a website.

This program runs on its own `m1.micro` instance on Amazon Web Services.
(That means you don't need to install anything other than an ssh client on your
computer to deploy Overview.)

# Install `overview-manage` script on your computer

1. Install `~/.aws/aws-overview-credentials.sh` [as we describe it on the Wiki](https://github.com/overview/overview-server/wiki/Deploying-from-scratch-to-amazon#amazon-web-services-aws-authentication)

2. Put this in a `bin` directory on your computer:
```sh
#!/bin/sh

. ~/.aws/aws-overview-credentials.sh
# Find MANAGE_SERVER public address at https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:
MANAGE_SERVER="ubuntu@ec2-XXX-XXX-XXX-XXX.compute-1.amazonaws.com"

if [ "$1" = "ssh" ]; then
  if [ -n "$2" ] && [ -n "$3" ]; then
    IP_ADDRESS_COMMAND="overview-manage status | grep '$2' | grep '$3' | head -n 1 | cut -f 4"
    SSH_COMMAND="ssh \$($IP_ADDRESS_COMMAND)"
    ssh -t "$MANAGE_SERVER" $SSH_COMMAND
  else
    ssh -t "$MANAGE_SERVER" "env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY bash --login"
  fi
else
  ssh -t "$MANAGE_SERVER" "env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY bash --login /usr/local/bin/overview-manage $@"
fi
```

# Quick start: Recipes

* To deploy new code (that has been built on Jenkins): `overview-manage deploy overview-server@_tag_ production`
* To deploy new code to only one machine: `overview-manage deploy overview-server@_tag_ production/web/10.x.x.x`

These all restart the running code on the servers. The restarts all happen within the same 30s. If Jenkins never published the tag's artifact, nothing happens.

# Usage

Commands look like this: `overview-manage COMMAND ARG1 ARG2 ...`

See "Concepts" below to understand what these commands do. This is a mere cheat-sheet.

| Command | Summary | Example | Duration |
| ------- | ------- | ------- | -------- |
| `publish` | Make "staging.zip" or "production.zip" point to the built zip | `overview-manage publish overview-server@deploy-2014-05-14.01 staging | 5s |
| `deploy` | Runs commands to restart components | `overview-manage deploy overview-server@deploy-2014-05-14.01 staging` (or `staging/worker`) | 5s per server |

Each of these commands runs the commands before it; if they've already been done, a quick verification will occur instead.

Want to deploy at a specific time? Run `publish` ahead of time, then `deploy` when you're ready.

# Concepts

Nouns:

* A **source** is a Git repository that contains code.
* A **version** is a version of the *source*, identified by a "tree-ish". (For instance: `master`, `tag1`, or `3fbd31873e7b220dcbe535e06099a1856051b935`.)
* An **artifact** is a set of files representing a compiled *source* at a given *version* (a zipfile).
* An **environment** is one of **production** or **staging**. We test stuff on *staging*; our live site is on *production*.
* A **machine** is an Amazon EC2 Instance. It runs in one *environment*. We identify it by its private IP address, e.g., `10.x.x.x`.
* A **machine type** is a recipe: it specifies *machine*'s configuration and instance type. We identify, say, `production/web`.

Verbs:

* You **build** a *source* to produce an *artifact* on S3. This happens on Jenkins, _not_ in this project.
* You **publish** an *artifact* to indicate, on S3, that it is the latest version in the given *environment*.
* You **restart** services on a *machine* to make it use the latest published version.
* You **deploy** services to a *machine* by running *publish* and *restart*.

Here's where things are stored:

| Bunch of files | Key properties | Where it is | What you can do with it |
| -------------- | -------------- | ----------- | ----------------------- |
| source | URL | GitHub | *build* at a given SHA1, using Jenkins |
| artifact | version | S3, `overview-builds/SHA1.zip` | *publish* |
| published artifact | nothing | S3, `overview-builds/ENVIRONMENT.zip` |

# Development

You need Ruby >= 2.0.

    bundle install
    bundle exec guard
    # and then edit code

Write a unit test that breaks; write code to fix it; repeat.
