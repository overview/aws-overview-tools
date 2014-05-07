module Operations
  class Install
    def initialize(component_artifact, machine)
      @component_artifact = component_artifact
      @machine = machine
    end

    def run
      @machine.shell do |shell|
        shell.ln_sf(@component_artifact.files_path, @component_artifact.install_path)
      end
    end
  end
end
