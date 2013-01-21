require_relative 'build_command'

module Commands
  class Build < BuildCommand
    def name
      'build'
    end

    def repository_name
      'main'
    end
  end
end
