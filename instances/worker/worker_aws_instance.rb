#!/usr/bin/env ruby

require_relative '../common/aws_instance'
require_relative 'worker_aws_image'

class WorkerAwsInstance < AwsInstance
  def image_class
    WorkerAwsImage
  end

  def default_instance_type
    'm3.large'
  end
end
