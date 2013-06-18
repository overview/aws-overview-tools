require_relative '../arguments/searcher'
require_relative '../arguments/treeish'
require_relative '../command'

module Commands
  class DeployCommand < Command
    def arguments_schema
      [ Arguments::Searcher.new, Arguments::Treeish.new ]
    end

    def project_names
      raise NoMethodError.new
    end

    def description
      "Builds and deploys the specified version of the #{repository} git repository to the specified machines."
    end

    def run(runner, searcher, treeish)
      project_names.each do |p| 
        project = runner.projects[p]
        project.fetch
        project.checkout(treeish)
        project.build
        instances = runner.instances.with_searcher(searcher)

        project.copy(searcher.env, instances)
        project.install(instances)
        project.restart(instances)

        "Deployed #{p} #{treeish} to #{instances.collect(&:to_s).join(' ')}"
      end
    end
  end
end
