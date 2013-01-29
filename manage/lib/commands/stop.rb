require_relative '../arguments/searcher'
require_relative '../command'

module Commands
  class Stop < Command
    def arguments_schema
      [ Arguments::Searcher.new ]
    end

    def name
      'stop'
    end

    def description
      "Stops all Overview-specific services (not Postgres) on the specified instances."
    end

    def run(runner, searcher)
      repository = runner.repositories['config']
      instances = runner.instances.with_searcher(searcher)
      repository.stop(instances)
      "Stopped all Overview-specific services (not Postgres) on #{instances.collect(&:to_s).join(' ')}"
    end
  end
end
