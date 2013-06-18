require_relative 'deploy_command'

module Commands
  class DeployConfig < DeployCommand
    def name
      'deploy-config'
    end

    def project_names
      ['config']
    end
  end
end
