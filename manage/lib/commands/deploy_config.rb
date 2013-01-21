require_relative 'deploy_command'

module Commands
  class DeployConfig < DeployCommand
    def name
      'deploy-config'
    end

    def repository_name
      'config'
    end
  end
end
