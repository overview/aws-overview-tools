#!/usr/bin/env ruby

require 'bundler/setup'

require_relative 'lib/manager_config'
require_relative 'lib/project_collection'
require_relative 'lib/runner'
require_relative 'lib/state'

config = ManagerConfig.new('config/config.yml')
projects = ProjectCollection.new(config)

state = State.new('state.yml')
runner = Runner.new(state, projects)

if ARGV.length > 0
  runner.run(*ARGV)
else
  $stderr.puts runner.usage
  exit(1)
end
