#!/usr/bin/env ruby
#
# Call this as follows:
#
# AWS_KEYPAIR_NAME=adamhooper ./create_images.rb
#
# This will create a bunch of AMI images.
#
# WARNING: it will also leave a bunch of instances running--one per image.
# You should check that these instances are configured as desired, then
# terminate them.

require 'bundler/setup'

require_relative 'common/aws_instance_collection'
require_relative 'vanilla/vanilla_aws_instance'
require_relative 'vanilla/vanilla_aws_image'

require_relative 'build/build_aws_image'
require_relative 'database/database_aws_image'
require_relative 'manage/manage_aws_image'
require_relative 'searchindex/searchindex_aws_image'
require_relative 'test_slave/test_slave_aws_image'
require_relative 'web/web_aws_image'
require_relative 'worker/worker_aws_image'

if !ENV['AWS_ACCESS_KEY_ID']
  raise Exception.new("You must specify the AWS_ACCESS_KEY_ID environment variable.")
end
if !ENV['AWS_SECRET_ACCESS_KEY']
  raise Exception.new("You must specify the AWS_SECRET_ACCESS_KEY environment variable.")
end
if !ENV['AWS_KEYPAIR_NAME']
  raise Exception.new("You must specify the AWS_KEYPAIR_NAME environment variable. It should be a keypair you can access.")
end

for image_class in [ BuildAwsImage, ManageAwsImage, DatabaseAwsImage, SearchIndexAwsImage, TestSlaveAwsImge, WebAwsImage, WorkerAwsImage ]
  puts "Creating #{image_class.name}..."
  puts "Spinning up vanilla instance..."
  instance = VanillaAwsInstance.new(:zone => 'us-east-1a', :instance_type => 'm3.large').create!
  unbuilt_image = image_class.new(:region => 'us-east-1', :arch => 'x86_64')
  image = unbuilt_image.build!(instance)
  puts "Created #{image_class.name}. AMI ID: #{image.ami_id}"
end

puts "All done. Be sure to terminate all those running instances!"
