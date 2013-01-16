require_relative '../command'
require_relative '../arguments/optional_searcher'

module Commands
  class Status < Command
    def name
      'status'
    end

    def arguments_schema
      [ Arguments::OptionalSearcher.new ]
    end

    def description
      "Shows which instances have been registered"
    end

    def run(runner, searcher_or_nil)
      state = runner.state
      instances = state.instances
      if searcher_or_nil
        instances = instances.with_searcher(searcher_or_nil)
      end

      lines = instances.map { |instance| "\t#{instance.env}\t#{instance.type}\t#{instance.ip_address}" }.join("\n")
      "Registered instances:\n#{lines}"
    end
  end
end
