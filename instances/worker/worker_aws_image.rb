#!/usr/bin/env ruby

require_relative '../common/aws_image'

class WorkerAwsImage < AwsImage
  def packages
    super + %w(
      openjdk-7-jre-headless
      rsyslog-relp
      libreoffice
    )
  end

  def self.type_tag
    'worker'
  end
end
