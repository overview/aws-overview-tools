require_relative 'base'
require_relative '../arguments/source_at_version'
require_relative '../arguments/machines'
require_relative '../pipeline_command_runner'

module Commands
  class DeployCommand < Base
    name 'deploy'
    description 'Publishes an Artifact and restarts services on the specified machines'
    arguments_schema [ Arguments::SourceAtVersion.new, Arguments::Machines.new ]

    def run(runner, source_at_version, machines)
      $log.info('publish') { "Deploying #{source_at_version.sha1} on #{machines}" }

      pipeline = PipelineCommandRunner.new(runner)
      pipeline.deploy(source_at_version.source, source_at_version.sha1, machines)
    end
  end
end
