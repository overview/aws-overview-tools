require_relative '../arguments/searcher'
require_relative '../command'

module Commands
  class Restart < Command
    def arguments_schema
      [ Arguments::Searcher.new ]
    end

    def name
      'restart'
    end

    def description
      "Restarts all Overview-specific services on the specified instances."
    end

    def run(runner, searcher)
      repository = runner.repositories['config']
      instances = runner.instances.with_searcher(searcher)
      repository.restart(instances)
      "Restarted all Overview-specific services on #{instances.collect(&:to_s).join(' ')}"
    end
  end
end
