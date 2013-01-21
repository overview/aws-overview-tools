require_relative 'build_command'

module Commands
  class BuildConfig < BuildCommand
    def name
      'build-config'
    end

    def repository_name
      'config'
    end
  end
end
