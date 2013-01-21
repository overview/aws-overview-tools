require_relative 'copy_command'

module Commands
  class Copy < CopyCommand
    def name
      'copy'
    end

    def repository_name
      'main'
    end
  end
end
