#!/usr/bin/env ruby

require_relative '../common/aws_image'

class DatabaseAwsImage < AwsImage
  def packages
    super + %w(
      postgresql
      rsyslog-relp
    )
  end

  def self.type_tag
    'database'
  end
end
