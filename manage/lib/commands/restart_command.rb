require_relative 'base'
require_relative '../arguments/machines'

module Commands
  class RestartCommand < Command
    name 'restart'
    description 'Calls restart scripts for Overview services on the specified machines'
    arguments_schema [ Arguments::Machines.new ]

    def run(runner, machines)
      pipeline = PipelineCommandRunner.new(runner)
      pipeline.restart(machines)
    end
  end
end
