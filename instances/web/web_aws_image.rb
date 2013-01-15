#!/usr/bin/env ruby

require_relative '../common/aws_image'

class WebAwsImage < AwsImage
  def packages
    super + [ 'nginx-light', 'openjdk-6-jre-headless' ]
  end

  def self.type_tag
    'web'
  end
end
