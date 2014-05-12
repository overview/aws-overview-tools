require_relative 'base'

module Arguments
  # Returns a Searcher for a particular instance.
  class Instance < Base
    def name
      'INSTANCE'
    end

    def description
      'specifies a particular instance (e.g., "production.web.10.1.2.3")'
    end

    def parse(runner, string)
      searcher = nil
      error = false

      begin
        searcher = ::Searcher.new(string)
      rescue ArgumentError
        error = true
      end

      if searcher && (!searcher.type || !searcher.ip_address)
        error = true
      end

      raise ArgumentError.new("'#{string}' does not specify an instance") if error

      searcher
    end
  end
end
