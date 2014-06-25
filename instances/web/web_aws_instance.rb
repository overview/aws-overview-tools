#!/usr/bin/env ruby

require_relative '../common/aws_instance'
require_relative 'web_aws_image'

class WebAwsInstance < AwsInstance
  def image_class
    WebAwsImage
  end

  def default_instance_type
    'm3.medium'
  end
end
