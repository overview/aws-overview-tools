#!/usr/bin/env ruby

require_relative '../worker/worker_aws_instance'

class SearchindexStagingAwsInstance < WorkerAwsInstance
  def security_group
    'worker-staging'
  end
end
