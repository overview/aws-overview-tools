#!/usr/bin/env ruby

require_relative '../common/aws_instance'
require_relative 'test_slave_aws_image'

class TestSlaveAwsInstance < AwsInstance
  def image_class
    TestSlaveAwsImage
  end

  def default_instance_type
    # Jenkins will issue a spot request for something faster; this method
    # will be ignored
    'm3.large'
  end
end
