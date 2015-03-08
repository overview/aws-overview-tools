require_relative '../log'

module Operations
  # Calls start_commands on the given machines.
  class Start
    attr_reader(:machine)

    def initialize(machine)
      @machine = machine
    end

    def run
      $log.info('start') { "Starting services on #{machine}" }
      machine.shell do |machine_shell|
        for command in machine.start_commands
          machine_shell.exec(command)
        end
      end
    end
  end
end
