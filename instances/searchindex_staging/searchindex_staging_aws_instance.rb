#!/usr/bin/env ruby

require_relative '../searchindex/searchindex_aws_instance'

class SearchindexStagingAwsInstance < SearchindexAwsInstance
  def security_group
    'searchindex-staging'
  end
end
