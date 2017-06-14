#!/usr/bin/env ruby

require 'aws-sdk'
require 'bundler/setup'
require 'yaml'

require_relative 'lib/runner'
require_relative 'lib/state'
require_relative 'lib/store'

ec2_client = Aws::EC2::Client.new
config = YAML.load_file('config/config.yml')
store = Store.from_yaml(config)
state = State.new(ec2_client)
runner = Runner.new(state, store, config)

if ARGV.length > 0
  runner.run(*ARGV)
else
  $stderr.puts runner.usage
  exit(1)
end
