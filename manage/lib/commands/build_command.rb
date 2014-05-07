require_relative 'base'
require 'arguments/source_at_version'

module Commands
  class BuildCommand < Base
    name 'build'
    description 'Checks out and builds the source at the specified version'
    arguments_schema [ Arguments::SourceAtVersion.new ]

    def run(runner, source_at_version)
      source = source_at_version.source
      version = source_at_version.version

      op = Operations::Build.new(source, version)
      op.run
    end
  end
end
