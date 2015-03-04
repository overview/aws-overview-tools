require_relative 'base'
require_relative '../arguments/source_at_version'
require_relative '../pipeline_command_runner'
require_relative '../log'

module Commands
  class RebuildCommand < Base
    name 'rebuild'
    description 'Builds the source at the specified version, clobbering cached versions'
    arguments_schema [ Arguments::SourceAtVersion.new ]

    def run(runner, source_at_version)
      pipeline = PipelineCommandRunner.new(runner)
      artifact = pipeline.rebuild(source_at_version.source, source_at_version.version)
      $log.info('rebuild') { "Reuilt #{artifact}" }
    end
  end
end
