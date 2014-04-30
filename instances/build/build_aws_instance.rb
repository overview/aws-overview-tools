#!/usr/bin/env ruby

require_relative '../common/aws_instance'
require_relative 'build_aws_image'

class SearchindexAwsInstance < AwsInstance
  def image_class
    BuildAwsImage
  end

  def default_instance_type
    'c3.large'
  end

  def security_group
    'build'
  end
end
