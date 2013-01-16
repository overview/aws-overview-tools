require_relative '../command'
require_relative '../arguments/optional_command'

module Commands
  class Help < Command
    def name
      'help'
    end

    def arguments_schema
      [ Arguments::OptionalCommand.new ]
    end

    def run(runner, command_or_nil)
      $stderr.puts (command_or_nil || runner).usage
    end
  end
end
