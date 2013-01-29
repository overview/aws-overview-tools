require_relative '../arguments/searcher'
require_relative '../command'

module Commands
  class Start < Command
    def arguments_schema
      [ Arguments::Searcher.new ]
    end

    def name
      'start'
    end

    def description
      "Starts all Overview-specific services (not Postgres) on the specified instances."
    end

    def run(runner, searcher)
      repository = runner.repositories['config']
      instances = runner.instances.with_searcher(searcher)
      repository.start(instances)
      "Started all Overview-specific services (not Postgres) on #{instances.collect(&:to_s).join(' ')}"
    end
  end
end
