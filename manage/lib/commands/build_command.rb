require_relative 'base'
require_relative '../arguments/source_at_version'
require_relative '../pipeline_command_runner'

module Commands
  class BuildCommand < Base
    name 'build'
    description 'Checks out and builds the source at the specified version'
    arguments_schema [ Arguments::SourceAtVersion.new ]

    def run(runner, source_at_version)
      pipeline = PipelineCommandRunner.new(runner)
      pipeline.build(source_at_version.source, source_at_version.version)
    end
  end
end
