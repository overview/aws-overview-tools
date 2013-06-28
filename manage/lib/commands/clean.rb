require_relative 'clean_command'

module Commands
  class Clean < CleanCommand
    def name
      'clean'
    end

    def project_names
      ['main', 'worker', 'documentset-worker', 'message-broker']
    end
  end
end
