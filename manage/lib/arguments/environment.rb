require_relative '../argument'

module Arguments
  # Parses out "staging" or "production".
  #
  # Input is of the form "staging" or "production".
  class Environment < Argument
    name 'ENVIRONMENT'
    description 'an environment: either "production" or "staging"'

    def parse(runner, string)
      if runner.environments.include?(string)
        string
      else
        raise ArgumentError.new("'#{string}' is not a valid environment. Valid environments are #{runner.environments.to_a.join(', ')}")
      end
    end
  end
end
