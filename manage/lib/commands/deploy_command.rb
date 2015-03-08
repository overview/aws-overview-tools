require_relative 'base'
require_relative '../arguments/source_at_version'
require_relative '../arguments/machines'

module Commands
  class DeployCommand < Base
    name 'deploy'
    description 'Publishes an Artifact and restarts services on the specified machines'
    arguments_schema [ Arguments::SourceAtVersion.new, Arguments::Machines.new ]

    def run(runner, source_at_version, machines)
      pipeline = PipelineCommandRunner.new(runner)
      pipeline.deploy(source_at_version.source, source_at_version.version, machines)
    end
  end
end
