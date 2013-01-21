require_relative '../command'

module Commands
  class FetchCommand < Command
    def arguments_schema
      []
    end

    def repository_name
      raise NoMethodError.new
    end

    def description
      "Updates the managed git #{repository_name} repository"
    end

    def run(runner)
      repository = runner.repositories[repository_name]
      repository.fetch
    end
  end
end
