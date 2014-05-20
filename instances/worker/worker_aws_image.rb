#!/usr/bin/env ruby

require_relative '../common/aws_image'

class WorkerAwsImage < AwsImage
  def packages
    super + [ 'openjdk-7-jre-headless', 'rsyslog-relp' ]
  end

  def self.type_tag
    'worker'
  end
end
