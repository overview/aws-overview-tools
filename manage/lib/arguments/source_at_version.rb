require_relative 'base'

module Arguments
  # Parses out a source name and version string.
  #
  # Input is of the form "overview-server" or "overview-server@master".
  class SourceAtVersion < Base
    RetvalType = Struct.new(:source, :version)
    # A git ref regex is too complicated, and it doesn't really solve the
    # problem of predicting whether or not a ref is valid. See discussion
    # here:
    # https://stackoverflow.com/questions/12093748/how-do-i-check-for-valid-git-branch-names
    # ... and then ignore it.
    #
    # Let's just use [-_/a-zA-Z0-9], which is all we use
    SourceAtVersionRegex = %r{^([-_a-zA-Z0-9\.]+)(?:@([-_/a-zA-Z0-9\.]+))?$}

    name 'SOURCE@VERSION'
    description 'a source at a specific version (e.g., "overview-server@master")'

    def parse(runner, string)
      match = SourceAtVersionRegex.match(string)

      raise ArgumentError.new("'#{string}' does not look like 'SOURCE@VERSION'. We use regex #{SourceAtVersionRegex.to_s}.") if !match

      source = runner.sources[match[1]]

      raise ArgumentError.new("'#{match[1]}' is not a valid source.") if !source

      version = match[2] || 'master'

      RetvalType.new(match[1], version)
    end
  end
end
