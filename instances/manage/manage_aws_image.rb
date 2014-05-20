#!/usr/bin/env ruby

require_relative '../common/aws_image'

class ManageAwsImage < AwsImage
  def packages
    super + [
      'git',
      'zip',
      'unzip',
      'rsyslog-relp',
      'ruby'
    ]
  end

  def self.type_tag
    'manage'
  end
end
