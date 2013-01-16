#!/usr/bin/env ruby

require 'bundler/setup'

require_relative 'lib/runner'
require_relative 'lib/state'

state = State.new('state.yml')
runner = Runner.new(state)

if ARGV.length > 0
  runner.run(*ARGV)
else
  $stderr.puts runner.usage
  exit(1)
end
