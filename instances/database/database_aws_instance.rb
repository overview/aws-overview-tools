#!/usr/bin/env ruby

require_relative '../common/aws_instance'
require_relative 'database_aws_image'

class DatabaseAwsInstance < AwsInstance
  def image_class
    DatabaseAwsImage
  end

  def default_instance_type
    'm3.medium' # it'll be IO-bound
  end
end
