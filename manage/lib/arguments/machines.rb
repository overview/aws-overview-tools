require_relative '../argument'

module Arguments
  # Parses a "machines specification" such as "production.web".
  #
  # Input is of the form "production", "production.web" or
  # "production.web.10.1.2.3". If the input does not specify any machines,
  # we throw an ArgumentError.
  class Machines < Argument
    name 'MACHINES'
    description 'running machines: "production", "staging.web", or "production.web.10.1.2.3", for instance'

    def parse(runner, string)
      if runner.machines_with_spec(string).empty?
        raise ArgumentError.new("the argument '#{string}' did not match any running machines")
      else
        string
      end
    end
  end
end
