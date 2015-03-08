require_relative '../log'

module Operations
  # Calls stop_commands on the given machines.
  class Stop
    attr_reader(:machine)

    def initialize(machine)
      @machine = machine
    end

    def run
      $log.info('stop') { "Stopping services on #{machine}" }
      machine.shell do |machine_shell|
        for command in machine.stop_commands
          machine_shell.exec(command)
        end
      end
    end
  end
end
