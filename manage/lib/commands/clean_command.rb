require_relative '../command'

module Commands
  class CleanCommand < Command
    def arguments_schema
      []
    end

    def repository_name
      raise NoMethodError.new
    end

    def description
      "Cleans the #{repository} directory, assuming it exists."
    end

    def run(runner)
      repository = runner.repositories[repository_name]
      repository.clean
    end
  end
end
