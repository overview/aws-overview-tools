require_relative '../arguments/searcher'
require_relative '../arguments/treeish'
require_relative '../command'

module Commands
  class CopyCommand < Command
    def arguments_schema
      [ Arguments::Searcher.new, Arguments::Treeish.new ]
    end

    def repository_name
      raise NoMethodError.new
    end

    def description
      "Builds and copies the specified version of the #{repository} git repository to the specified machines."
    end

    def run(runner, searcher, treeish)
      repository = runner.repositories[repository_name]
      repository.fetch
      repository.checkout(treeish)
      repository.build
      repository.copy(searcher.env, runner.instances.with_searcher(searcher))
    end
  end
end
