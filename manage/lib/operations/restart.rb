require_relative '../log'

module Operations
  # Calls restart_commands on the given machines.
  class Restart
    attr_reader(:machine)

    def initialize(machine)
      @machine = machine
    end

    def run
      $log.info('restart') { "Restarting services on #{machine}" }
      machine.shell do |machine_shell|
        for command in machine.restart_commands
          machine_shell.exec(command)
        end
      end
    end
  end
end
