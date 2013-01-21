require_relative '../command'

module Commands
  class BuildCommand < Command
    def arguments_schema
      [ Arguments::Treeish.new ]
    end

    def repository_name
      raise NoMethodError.new
    end

    def description
      "Checks out and builds the specified version of the #{repository} git repository."
    end

    def run(runner, treeish)
      repository = runner.repositories[repository_name]
      repository.fetch
      repository.checkout(treeish)
      repository.build
    end
  end
end
