#!/usr/bin/env ruby

class AwsVolume
  attr_reader(:type_tag, :security_group, :region, :size)

  def initialize
    @type_tag = '(none)'
    @security_group = 'default'
    @zone = 'us-east-1a'
    @size = '10' # in GiB
  end

  def volume_id
    @_volume_id ||= begin
    end
  end
end
