require_relative '../log'

module Operations
  # Pushes a ComponentArtifact to a Machine.
  #
  # Usage:
  #
  #     component_artifact = ... a ComponentArtifact ...
  #     machine = ... a Machine ...
  #     Publish.new(component_artifact, machine).run
  #
  # When you run, Publish does this:
  #
  # 1. Uploads the ComponentArtifact's files to the same path on the target machine
  # 2. Deletes old component artifacts on the target machine
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

        ret = shell.rm_rf(@component_artifact.path) && \
          shell.exec("sudo mkdir -p /opt/overview && sudo chown ubuntu:ubuntu /opt/overview") && \
          shell.mkdir_p(File.dirname(@component_artifact.path)) && \
          shell.upload_r(@component_artifact.path, @component_artifact.path)

        Cleaner.clean(:component_artifacts, shell) if ret

        ret
      end
    end
  end
end
