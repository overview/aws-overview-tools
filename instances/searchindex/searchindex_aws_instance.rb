#!/usr/bin/env ruby

require_relative '../common/aws_instance'
require_relative './searchindex_aws_image'

class SearchindexAwsInstance < AwsInstance
  def image_class
    SearchindexAwsImage
  end

  def security_group
    'searchindex'
  end

  def default_instance_type
    'm3.large'
  end
end
