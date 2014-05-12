require_relative 'base'
require_relative '../arguments/source_at_version'
require_relative '../arguments/environment'

module Commands
  class PrepareCommand < Base
    name 'prepare'
    description 'Bundles all components of the source at the specified version'
    arguments_schema [ Arguments::SourceAtVersion.new, Arguments::Environment.new ]

    def run(runner, source_at_version, environment)
      pipeline = PipelineCommandRunner.new(runner)
      pipeline.prepare(source_at_version.source, source_at_version.version, environment)
    end
  end
end
