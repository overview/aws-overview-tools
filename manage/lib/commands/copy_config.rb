require_relative 'copy_command'

module Commands
  class CopyConfig < CopyCommand
    def name
      'copy-config'
    end

    def project_names
      ['config']
    end
  end
end
