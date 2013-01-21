require_relative 'fetch_command'

module Commands
  class FetchConfig < FetchCommand
    def name
      'fetch-config'
    end

    def repository_name
      'config'
    end
  end
end
