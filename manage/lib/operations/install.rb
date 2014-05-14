require_relative '../log'

module Operations
  class Install
    def initialize(component_artifact, machine)
      @component_artifact = component_artifact
      @machine = machine
    end

    def run
      $log.info('install') { "Installing to #{@machine.to_s}" }
      @machine.shell do |shell|
        shell.ln_sfT(@component_artifact.files_path, @component_artifact.install_path)
      end
    end
  end
end
