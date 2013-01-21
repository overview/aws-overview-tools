require_relative '../argument'

require_relative '../searcher'

module Arguments
  # Returns a Searcher or nil
  class Searcher < Argument
    def name
      'INSTANCES-GROUP'
    end

    def description
      'specifies an instance or group of instances (e.g., "production" or "staging.web")'
    end

    def parse(runner, string_or_nil)
      if string_or_nil.nil? || string_or_nil.empty?
        raise ArgumentError.new("You must specify INSTANCES_GROUP")
      else
        ::Searcher.new(string_or_nil)
      end
    end
  end
end
