require_relative 'base'
require_relative '../arguments/source_at_version'
require_relative '../arguments/machines'

module Commands
  class PublishCommand < Base
    name 'publish'
    description 'Pushes components to the specified machines'
    arguments_schema [ Arguments::SourceAtVersion.new, Arguments::Machines.new ]

    def run(runner, source_at_version, machines)
      pipeline = PipelineCommandRunner.new(runner)
      pipeline.publish(source_at_version.source, source_at_version.version, machines)
    end
  end
end
