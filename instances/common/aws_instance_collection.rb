#!/usr/bin/env ruby

require 'aws'

class AwsInstanceCollection
  include Enumerable

  attr_reader(:instance_class, :zone, :arch)

  def initialize(instance_class, options)
    @instance_class = instance_class
    @zone = options[:zone]
    @arch = options[:arch]
  end

  def each
    AWS::EC2.new.instances
      .filter('availability-zone', zone)
      .filter('architecture', arch)
      .filter('tag:type', instance_class.type_tag)
      .each do |instance|

      yield instance_class.new(instance)
    end
  end
end
