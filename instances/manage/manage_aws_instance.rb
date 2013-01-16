#!/usr/bin/env ruby

require_relative '../common/aws_instance'
require_relative 'manage_aws_image'

class ManageAwsInstance < AwsInstance
  def image_class
    ManageAwsImage
  end

  def default_arch
    'x86_64'
  end

  def default_instance_type
    'm1.small'
  end
end
