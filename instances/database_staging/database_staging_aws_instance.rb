#!/usr/bin/env ruby

require_relative '../database/database_aws_instance'

class DatabaseStagingAwsInstance < DatabaseAwsInstance
  def default_instance_type
    'm1.medium' # Should be large, but let's be cheap
  end

  def security_group
    'database-staging'
  end
end
