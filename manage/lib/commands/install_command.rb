require_relative 'base'
require_relative '../arguments/source_at_version'
require_relative '../arguments/machines'

module Commands
  class InstallCommand < Base
    name 'install'
    description 'Symlinks published components on the specified machines, such that restarting would cause them to run'
    arguments_schema [ Arguments::SourceAtVersion.new, Arguments::Machines.new ]

    def run(runner, source_at_version, machines)
      pipeline = PipelineCommandRunner.new(runner)
      pipeline.install(source_at_version.source, source_at_version.version, machines)
    end
  end
end
