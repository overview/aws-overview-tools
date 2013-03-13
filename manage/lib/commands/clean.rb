require_relative 'clean_command'

module Commands
  class Clean < CleanCommand
    def name
      'clean'
    end

    def repository_name
      'main'
    end
  end
end
