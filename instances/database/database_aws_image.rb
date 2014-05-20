#!/usr/bin/env ruby

require_relative '../common/aws_image'

class DatabaseAwsImage < AwsImage
  def packages
    super + [ 'postgresql-9.1', 'rsyslog-relp' ]
  end

  def self.type_tag
    'database'
  end
end
