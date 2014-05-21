require 'open3'

require_relative 'base'
require_relative '../log'

module CommandExecutors
  # Executes commands on the local machine.
  class Local < Base
    def exec_command(command)
      $log.info('local') { "Running #{command}" }

      # It's hard to stream output, because we have to use select and read
      # one line at a time. So let's skip it and assume the command runs
      # quickly and only writes to either stderr _or_ stdout.
      stdout, stderr, status = Open3.capture3(command)

      stdout.each_line do |line|
        $log.info('local') { line.chomp }
      end

      stderr.each_line do |line|
        $log.warn('local') { line.chomp }
      end

      msg = "Command exited with status #{status.exitstatus}"
      if status.success?
        $log.info('local') { msg }
        stdout
      else
        raise CommandFailedException.new(msg)
      end
    end
  end
end
