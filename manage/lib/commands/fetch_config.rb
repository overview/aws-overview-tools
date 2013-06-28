require_relative 'fetch_command'

module Commands
  class FetchConfig < FetchCommand
    def name
      'fetch-config'
    end

    def project_names
      ['config']
    end
  end
end
