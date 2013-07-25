#!/usr/bin/env ruby

require_relative '../worker/worker_aws_instance'

class SearchindexStagingAwsInstance < WorkerAwsInstance
  def security_group
    'searchindex-staging'
  end
end
