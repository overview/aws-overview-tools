require_relative '../log'

module Operations
  class Publish
    attr_reader(:component_artifact, :machine)

    def initialize(component_artifact, machine)
      @component_artifact = component_artifact
      @machine = machine
    end

    def run
      $log.info('publish') { "Publishing #{@component_artifact.path} to #{@machine.to_s}" }
      machine.shell do |shell|
        if shell.is_component_artifact_valid?(@component_artifact.path)
          return true
        end

        shell.rm_rf(@component_artifact.path) && \
        shell.mkdir_p(File.dirname(@component_artifact.path)) && \
        shell.upload_r(@component_artifact.path, @component_artifact.path)
      end
    end
  end
end
