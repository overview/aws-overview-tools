#!/usr/bin/env ruby

require 'tempfile'

require 'trollop'

require 'vanilla/vanilla_aws_image'

opts = Trollop::options do
  banner <<-EOS
Creates a new AMI for mounting in new EBS-backed instances.

Usage:

        create-image [options]

where [options] are:
EOS

  opt(:type, 'Instance type ("database", "worker", "server", etc)', :type => :string, :required => true)
  opt(:zone, 'AWS zone where the instance will be created (it will be available to the zone\'s region)', :default => 'us-east-1a')
  opt(:build_machine_type, 'Machine type that will be used to build the image', :default => 'm1.small')
end

machine_type = opts[:type]
machine_type_caps = machine_type.gsub(/(?:\b|_)([a-z])/) { |s| s[-1].upcase }
region = opts[:zone][0...-1]

require "#{machine_type}/#{machine_type}_aws_image"

Image = Object.const_get("#{machine_type_caps}Image")
image = Image.new

vanilla = VanillaAwsImage.new(:region => region)
vanilla.with_running_instance(:availability_zone => opts[:zone], :instance_type => opts[:build_machine_type]) do |instance|
  hostname = instance.dns_name

  puts "Sending your PRIVATE X.509 KEY to #{hostname}..."


  puts "Sending creation script to #{hostname}..."
  f = Tempfile.open("t.sh")
  begin
    f.write(image.creation_script)
    f.flush()
    `scp #{f.path} #{vanilla.username}@#{hostname}:t.sh`
  ensure
    f.close!
  end

  puts "Running creation script on #{hostname}..."
  `ssh #{vanilla.username}@#{hostname} 'sh ./t.sh'`

  puts 'Saving image'

end

image = image.new(:zone => opts[:zone])
ami_id = image.create()
puts "Image created. ID: #{ami_id}"
