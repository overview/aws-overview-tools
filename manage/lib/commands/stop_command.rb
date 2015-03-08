require_relative 'base'
require_relative '../arguments/machines'

module Commands
  class StopCommand < Command
    name 'stop'
    description 'Calls stop scripts for Overview services on the specified machines'
    arguments_schema [ Arguments::Machines.new ]

    def run(runner, machines)
      pipeline = PipelineCommandRunner.new(runner)
      pipeline.stop(machines)
    end
  end
end
