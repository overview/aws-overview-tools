#!/usr/bin/env ruby

require_relative '../common/aws_image'

class SearchindexAwsImage < AwsImage
  def packages
    super + %w(
      openjdk-7-jre-headless
      rsyslog-relp
    )
  end

  def self.type_tag
    'searchindex'
  end
end
