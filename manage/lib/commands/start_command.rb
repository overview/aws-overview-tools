require_relative 'base'
require_relative '../arguments/machines'

module Commands
  class StartCommand < Command
    name 'start'
    description 'Calls start scripts for Overview services on the specified machines'
    arguments_schema [ Arguments::Machines.new ]

    def run(runner, machines)
      pipeline = PipelineCommandRunner.new(runner)
      pipeline.start(machines)
    end
  end
end
