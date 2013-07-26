#!/usr/bin/env ruby

require_relative '../worker/worker_aws_instance'

class SearchindexAwsInstance < WorkerAwsInstance
  def security_group
    'searchindex'
  end
end
