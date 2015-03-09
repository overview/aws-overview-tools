#!/bin/sh
# Wrapper for manage.rb.
#
# Symlink this file into /usr/local/bin. It will follow the symlink to this
# directory and execute the command you give.

CONFIG_DIR=/opt/overview/config/manage
DIR="$(dirname "$(readlink -f "$0")")"

export AWS_DEFAULT_REGION=us-east-1
export AWS_REGION=us-east-1

(cd "$DIR" && ./manage.rb $@)
