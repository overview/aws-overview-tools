#!/usr/bin/env ruby

require 'aws'
require 'httparty'

require_relative '../common/aws_image'

BASE_AMI_LISTINGS = 'http://cloud-images.ubuntu.com/releases/trusty/release/'

# Represents the "vanilla" image -- i.e., vanilla Ubuntu
class VanillaAwsImage < AwsImage
  def initialize(options)
    super(options)
  end

  def find_ec2_image
    response = HTTParty.get(BASE_AMI_LISTINGS)
    raise Exception.new("Invalid HTTP response from #{BASE_AMI_LISTINCGS}: #{response.code}") if response.code != 200
    text = response.gsub(/<[^>]+>/, ' ')
    ami_id = if text =~ /#{region}\s+#{arch_as_ubuntu_string}\s+ebs\s+Launch\s+([^\s]*)\s/
      $1
    else
      raise Exception.new("Could not find AMI for #{region}/#{arch_as_ubuntu_string} in HTML: #{response} -- and text: #{text}")
    end
    image = AWS::EC2.new.regions[region].images[ami_id]
  end

  def self.type_tag
    'vanilla'
  end

  protected

  def arch_as_ubuntu_string
    arch == 'i386' && '32-bit' || '64-bit'
  end
end
