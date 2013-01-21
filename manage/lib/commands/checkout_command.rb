require_relative '../arguments/treeish'
require_relative '../command'

module Commands
  class CheckoutCommand < Command
    def arguments_schema
      [ Arguments::Treeish.new ]
    end

    def repository_name
      raise NoMethodError.new
    end

    def description
      "Checks out the specified version of the #{repository} git repository for procesing."
    end

    def run(runner, treeish)
      repository = runner.repositories[repository_name]
      repository.fetch
      repository.checkout(treeish)
    end
  end
end
