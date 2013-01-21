require_relative 'copy_command'

module Commands
  class CopyConfig < CopyCommand
    def name
      'copy-config'
    end

    def repository_name
      'config'
    end
  end
end
