require_relative '../command'

module Commands
  class Status < Command
    def name
      'status'
    end

    def arguments_schema
      []
    end

    def description
      "Shows which instances have been registered"
    end

    def run(runner)
      state = runner.state
      instances = state.instances
      lines = instances.map { |instance| "\t#{instance.env}\t#{instance.type}\t#{instance.ip_address}" }.join("\n")
      "Registered instances:\n#{lines}"
    end
  end
end
