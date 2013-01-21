require_relative 'fetch_command'

module Commands
  class Fetch < FetchCommand
    def name
      'fetch'
    end

    def repository_name
      'main'
    end
  end
end
