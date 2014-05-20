#!/usr/bin/env ruby

require_relative '../common/aws_image'

# Web servers use haproxy as an SSL endpoint.
# We'd use nginx, which comes with Ubuntu by default, but it buffers requests,
# which would break file uploads for us.
HAPROXY_VERSION='1.5-dev17'
HAPROXY_DIRNAME="haproxy-#{HAPROXY_VERSION}"
HAPROXY_BASENAME="#{HAPROXY_DIRNAME}.tar.gz"
HAPROXY_URL="http://haproxy.1wt.eu/download/1.5/src/devel/#{HAPROXY_BASENAME}"

class WebAwsImage < AwsImage
  # We need to build HAProxy from scratch
  def packages
    super + [ 'openjdk-7-jre-headless', 'build-essential', 'libpcre3-dev', 'libssl-dev', 'rsyslog-relp' ]
  end

  def run_ssh_commands(ssh)
    super(ssh)

    build_commands = [
      'mkdir /tmp/haproxy',
      'cd /tmp/haproxy',
      "wget '#{HAPROXY_URL}'",
      "tar zxf #{HAPROXY_BASENAME}",
      "cd #{HAPROXY_DIRNAME}",
      'make TARGET=linux2628 USE_STATIC_PCRE=1 USE_OPENSSL=1',
      'sudo make PREFIX=/opt/haproxy install',
      'cd',
      'rm -rf /tmp/haproxy'
    ]

    ssh.exec("(#{build_commands.join(' && ')})")
  end

  def self.type_tag
    'web'
  end
end
