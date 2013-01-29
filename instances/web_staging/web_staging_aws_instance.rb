#!/usr/bin/env ruby

require_relative '../web/web_aws_instance'

class WebStagingAwsInstance < WebAwsInstance
  def security_group
    'web-staging'
  end
end
