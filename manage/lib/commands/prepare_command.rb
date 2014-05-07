require_relative 'base'
require 'arguments/source_at_version'

module Commands
  class PrepareCommand < Base
    name 'prepare'
    description 'Bundles all components of the source at the specified version'
    arguments_schema [ Arguments::SourceAtVersion.new ]

    def run(runner, source_at_version)
      source = source_at_version.source
      version = source_at_version.version

      source_artifact = Operations::Build.new(source, version).run # may be very fast

      components = runner.components_with_source(source.name)

      components.each do |component|
        prepare = Operations::Prepare.new(source_artifact, component)
        prepare.run
      end
    end
  end
end
