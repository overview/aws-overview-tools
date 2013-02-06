#!/usr/bin/env ruby
#
# Call this as follows:
#
# ./create_instance.rb TYPE ZONE
#
# Where TYPE is 'manage', 'worker', 'web', or 'database'
# and ZONE is 'us-east-1a'
#
# This only starts new instances; it doesn't start any services on them or
# alert anybody of their presence.
#
# Wait until the install is finished, then use overview-manage to add the
# new IP address, deploy-config, and deploy.

require 'bundler/setup'

ENV['AWS_ACCESS_KEY_ID'] = `cat ~/.aws/aws-credential-file.txt | grep AWSAccessKeyId | cut -d '=' -f 2`.strip
ENV['AWS_SECRET_ACCESS_KEY'] = `cat ~/.aws/aws-credential-file.txt | grep AWSSecretKey | cut -d '=' -f 2`.strip

if !ENV['AWS_KEYPAIR_NAME']
  raise Exception.new("You must specify the AWS_KEYPAIR_NAME environment variable. It should be a keypair you can access.")
end

def usage
  $stderr.puts "Usage: #{$0} TYPE ZONE"
  $stderr.puts "For instance: #{$0} web us-east-1a"
  exit(1)
end

type = ARGV[0] || usage
zone = ARGV[1] || usage

require_relative "#{type}/#{type}_aws_instance"
instance_class = Object.const_get("#{type.gsub(/(?:^|[-_])(\w)/) { $1.upcase }}AwsInstance")

instance = instance_class.new(:zone => zone).created!
puts "Waiting for new #{type} instance to start..."
sleep 1 while instance.ec2_instance.status != :running
sleep 3 # for SSH to spin up
puts "Instance started. Private IP address: #{instance.private_ip_address}"

partial_type = type.split('_').first
production_or_staging = type.split('_').last == 'staging' && 'staging' || 'production'
specifier = "#{production_or_staging}.#{partial_type}.#{instance.private_ip_address}"

puts ""
puts "Your next steps:"
puts ""
puts "1. overview-manage add-instance #{specifier}"
puts "2. overview-manage ssh #{production_or_staging} #{partial_type} to accept its identity"
puts "3. overview-manage deploy-config #{specifier} [CONFIG_VERSION]"
puts "4. overview-manage deploy #{specifier} [OVERVIEW_VERSION]"
