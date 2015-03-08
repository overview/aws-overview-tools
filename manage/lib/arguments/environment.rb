require_relative 'base'

module Arguments
  # Parses out "staging" or "production".
  #
  # Input is of the form "staging" or "production".
  class Environment < Base
    name 'ENVIRONMENT'
    description 'an environment: either "production" or "staging"'

    def parse(runner, string)
      if [ 'production', 'staging' ].include?(string)
        string
      else
        raise ArgumentError.new("'#{string}' is not a valid environment. Valid environments are 'staging' and 'production'")
      end
    end
  end
end
