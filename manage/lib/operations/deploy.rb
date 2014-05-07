module Operations
  class Deploy
    def initialize(component, machine)
      @component = component
      @machine = machine
    end

    def run
      @machine.shell do |shell|
        @component.deploy_commands.all? do |command|
          shell.exec(command)
        end
      end
    end
  end
end
