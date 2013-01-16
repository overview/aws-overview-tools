require_relative '../argument'

module Arguments
  class OptionalCommand < Argument
    def name
      'COMMAND'
    end

    def description
      'is a command'
    end

    def parse(runner, string)
      runner.commands[string]
    end
  end
end
