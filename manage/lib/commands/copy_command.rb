require_relative '../arguments/searcher'
require_relative '../arguments/treeish'
require_relative '../project_command'

module Commands
  class CopyCommand < ProjectCommand
    def arguments_schema
      [ Arguments::Searcher.new, Arguments::Treeish.new ]
    end

    def description
      "Builds and copies the specified version of the git repository to the specified machines for #{projects}."
    end

    def run_on_project(project, searcher, treeish)
      project.fetch
      project.checkout(treeish)
      project.build
      instances = runner.instances.with_searcher(searcher)

      project.copy(searcher.env, instances)
    end
  end
end
