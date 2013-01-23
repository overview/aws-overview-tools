require_relative '../arguments/searcher'
require_relative '../arguments/treeish'
require_relative '../command'

module Commands
  class DeployCommand < Command
    def arguments_schema
      [ Arguments::Searcher.new, Arguments::Treeish.new ]
    end

    def repository_name
      raise NoMethodError.new
    end

    def description
      "Builds and deploys the specified version of the #{repository} git repository to the specified machines."
    end

    def run(runner, searcher, treeish)
      repository = runner.repositories[repository_name]
      repository.fetch
      repository.checkout(treeish)
      repository.build

      instances = runner.instances.with_searcher(searcher)

      repository.copy(searcher.env, instances)
      repository.install(instances)
      repository.restart(instances)
      "Deployed #{repository_name} #{treeish} to #{instances.collect(&:to_s).join(' ')}"
    end
  end
end
