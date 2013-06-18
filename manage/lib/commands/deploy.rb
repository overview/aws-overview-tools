require_relative 'deploy_command'

module Commands
  class Deploy < DeployCommand
    def name
      'deploy'
    end

    def project_names
      ['main', 'worker', 'documentset-worker', 'message-broker']
    end
  end
end
