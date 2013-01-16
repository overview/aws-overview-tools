#!/usr/bin/env ruby

require 'aws'

class AwsInstance
  attr_reader(:ec2_instance)

  def initialize(ec2_instance_or_options)
    if ec2_instance_or_options.respond_to?(:id)
      @ec2_instance = ec2_instance_or_options
    else
      @options = {}.merge(ec2_instance_or_options)
    end
  end

  def created!
    create! if ec2_instance.nil?
    self
  end

  def create!
    raise Exception.new("EC2 instance already exists") if ec2_instance

    options = {
      :availability_zone => zone,
      :security_groups => security_group,
      :instance_type => instance_type,
      :key_name => ENV['AWS_KEYPAIR_NAME']
    }

    @ec2_instance = image.created!.ec2_image.run_instance(options)
  end

  def ec2_instance_or_error
    raise Exception.new("EC2 instance does not exist") if !ec2_instance
    ec2_instance
  end

  def image
    image_class.new(:region => region, :arch => arch, :type_tag => type_tag)
  end

  def zone
    ec2_instance && ec2_instance.availability_zone || @options[:zone]
  end

  def region
    zone.chop
  end

  def type_tag
    image_class.type_tag
  end

  def security_group
    type_tag
  end

  def arch
    ec2_instance && ec2_instance.architecture.to_s || @options[:arch] || default_arch
  end

  def instance_type
    ec2_instance && ec2_instance.instance_type || @options[:instance_type] || default_instance_type
  end

  def default_arch
    'x86_64'
  end

  def default_instance_type
    'm1.micro' # because if we make a mistake, it's a cheap one.
  end

  def ip_address
    ec2_instance_or_error.ip_address
  end

  def private_ip_address
    ec2_instance_or_error.private_ip_address
  end

  protected

  def image_class
    raise NotImplementedError.new('Implement image_class')
  end
end
