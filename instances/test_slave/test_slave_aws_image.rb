#!/usr/bin/env ruby

require_relative '../common/aws_image'

class TestSlaveAwsImage < AwsImage
  # We need to build HAProxy from scratch
  def packages
    super + %w(
      build-essential
      nodejs
      nodejs-dev
      openjdk-7-jre-headless
      postgresql-9.3
      python
      wget
    )
  end

  def self.type_tag
    'test_slave'
  end
end
