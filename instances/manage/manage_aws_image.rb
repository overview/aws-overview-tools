#!/usr/bin/env ruby

require_relative '../common/aws_image'

class ManageAwsImage < AwsImage
  def packages
    super + [
      'git',
      'unzip',
      'openjdk-7-jdk',
      'ruby'
    ]
  end

  def self.type_tag
    'manage'
  end
end
