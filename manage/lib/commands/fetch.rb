require_relative 'fetch_command'

module Commands
  class Fetch < FetchCommand
    def name
      'fetch'
    end

    def project_names
      ['main', 'worker', 'documentset-worker', 'message-broker']
    end
  end
end
