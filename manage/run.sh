#!/bin/sh
# Wrapper for manage.rb.
#
# Symlink this file into /usr/local/bin. It will follow the symlink to this
# directory and execute the command you give.

CONFIG_DIR=/opt/overview/config/manage
DIR="$(dirname "$(readlink -f "$0")")"

(cd "$DIR" && ./manage.rb $@)
