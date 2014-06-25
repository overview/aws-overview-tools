#!/usr/bin/env ruby

require_relative '../database/database_aws_instance'

class DatabaseStagingAwsInstance < DatabaseAwsInstance
  def security_group
    'database-staging'
  end
end
