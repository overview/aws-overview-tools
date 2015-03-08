require_relative 'base'
require_relative '../arguments/source_at_version'
require_relative '../arguments/environment'

module Commands
  class PublishCommand < Base
    name 'publish'
    description 'Marks an Artifact as the official version for an environment'
    arguments_schema [ Arguments::SourceAtVersion.new, Arguments::Environment.new ]

    def run(runner, source_at_version, environment)
      pipeline = PipelineCommandRunner.new(runner)
      pipeline.publish(source_at_version.source, source_at_version.version, environment)
    end
  end
end
