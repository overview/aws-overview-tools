#!/usr/bin/env ruby

require 'bundler/setup'
require 'yaml'

require_relative 'lib/runner'
require_relative 'lib/state'
require_relative 'lib/store'

config = YAML.load_file('config/config.yml')

store = Store.from_yaml(config)
state = State.new('state.yml')
runner = Runner.new(state, store)

if ARGV.length > 0
  runner.run(*ARGV)
else
  $stderr.puts runner.usage
  exit(1)
end
