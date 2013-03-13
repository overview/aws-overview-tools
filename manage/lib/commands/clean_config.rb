require_relative 'clean_command'

module Commands
  class CleanConfig < CleanCommand
    def name
      'clean-config'
    end

    def repository_name
      'config'
    end
  end
end
