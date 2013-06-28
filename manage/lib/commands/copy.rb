require_relative 'copy_command'

module Commands
  class Copy < CopyCommand
    def name
      'copy'
    end

    def project_names
      ['main', 'worker', 'documentset-worker', 'message-broker']
    end
  end
end
