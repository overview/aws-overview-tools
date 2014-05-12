require_relative '../log'

module Operations
  class Deploy
    attr_reader(:component, :machine) # for the ERB binding

    def initialize(component, machine)
      @component = component
      @machine = machine
    end

    def run
      $log.info('deploy') { "Deploying to #{@machine.to_s}" }
      @machine.shell do |shell|
        @component.deploy_commands.all? do |command|
          # Normally we'd create a custom binding, but why bother? This isn't
          # a security issue because we're the ones writing the YAML.
          real_command = ERB.new(command).result(binding)
          shell.exec(real_command)
        end
      end
    end
  end
end
