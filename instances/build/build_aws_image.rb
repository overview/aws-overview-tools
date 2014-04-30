#!/usr/bin/env ruby

require_relative '../common/aws_image'

class BuildAwsImage < AwsImage
  def packages
    super + [ 'openjdk-7-jre-headless', 'build-essential', 'nodejs', 'nodejs-dev', 'npm' ]
  end

  def self.type_tag
    'build'
  end
end
