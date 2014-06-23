#!/usr/bin/env ruby

require_relative '../worker/worker_aws_instance'

class WorkerStagingAwsInstance < WorkerAwsInstance
  def security_group
    'worker-staging'
  end

  def default_instance_type
    'm3.medium'
  end
end
