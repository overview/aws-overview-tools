#!/usr/bin/env ruby1.8

require 'aws'

require_relative '../common/aws_instance'
require_relative './vanilla_aws_image'

# A basic Ubuntu instance
class VanillaAwsInstance < AwsInstance
  def initialize(options)
    super(options.merge(:type_tag => VanillaAwsInstance.type_tag))
  end

  def security_group
    'default'
  end

  protected

  def image_class
    VanillaAwsImage
  end

  def self.type_tag
    'vanilla'
  end
end
