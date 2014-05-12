require_relative 'base'

module Arguments
  class OptionalCommand < Base
    name 'COMMAND'
    description 'is a command'

    def parse(runner, string)
      runner.commands[string]
    end
  end
end
