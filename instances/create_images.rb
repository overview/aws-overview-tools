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

require_relative 'database/database_aws_image'
require_relative 'manage/manage_aws_image'
require_relative 'web/web_aws_image'
require_relative 'worker/worker_aws_image'

ENV['AWS_ACCESS_KEY_ID'] = `cat ~/.aws/aws-credential-file.txt | grep AWSAccessKeyId | cut -d '=' -f 2`.strip
ENV['AWS_SECRET_ACCESS_KEY'] = `cat ~/.aws/aws-credential-file.txt | grep AWSSecretKey | cut -d '=' -f 2`.strip

if !ENV['AWS_KEYPAIR_NAME']
  raise Exception.new("You must specify the AWS_KEYPAIR_NAME environment variable. It should be a keypair you can access.")
end

for image_class in [ ManageAwsImage, DatabaseAwsImage, WebAwsImage, WorkerAwsImage ]
  puts "Creating #{image_class.name}..."
  puts "Spinning up vanilla instance..."
  instance = VanillaAwsInstance.new(:zone => 'us-east-1a').create!
  unbuilt_image = image_class.new(:region => 'us-east-1', :arch => 'x86_64')
  image = unbuilt_image.build!(instance)
  puts "Created #{image_class.name}. AMI ID: #{image.ami_id}"
end

puts "All done. Be sure to terminate all those running instances!"
