require_relative 'base'

module Arguments
  # Parses out a source name and version string.
  #
  # Input is of the form "overview-server" or "overview-server@master".
  class SourceAtVersion < Base
    RetvalType = Struct.new(:source, :version, :sha1)

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

      sha1 = revparse(source, version)
      crash_unless_exists(source, sha1)

      RetvalType.new(match[1], version, sha1)
    end

    private
    
    def revparse(source, treeish)
      ret = if treeish =~ /\A[a-zA-Z0-9]{40}\Z/
        # https://github.com/schacon/ruby-git/issues/155
        treeish
      else
        `git ls-remote "#{source.url}" "#{treeish}" | cut -b1-40`.strip
      end

      raise ArgumentError.new("Could not get sha1 from remote for version '#{treeish}'") if ret.empty?
      $log.info('source_at_version') { "Revparse of #{treeish}: #{ret}" }
      ret
    end

    def crash_unless_exists(source, sha1)
      if !source.s3_bucket.exists?("#{sha1}.zip")
        raise ArgumentError.new("Jenkins has not published #{sha1}.zip. It must be there for overview-manage to work.")
      end
    end
  end
end
