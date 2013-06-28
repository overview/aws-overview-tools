require_relative 'build_command'

module Commands
  class BuildConfig < BuildCommand
    def name
      'build-config'
    end

    def project_names
      ['config']
    end
  end
end
