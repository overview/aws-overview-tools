require_relative 'build_command'

module Commands
  class Build < BuildCommand
    def name
      'build'
    end

    def project_names
      ['main', 'worker', 'documentset-worker', 'message-broker', 'search-index']
    end
  end
end
