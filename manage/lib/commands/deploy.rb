require_relative 'deploy_command'

module Commands
  class Deploy < DeployCommand
    def name
      'deploy'
    end

    def repository_name
      'main'
    end
  end
end
