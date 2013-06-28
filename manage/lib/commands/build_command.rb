require_relative '../project_command'

module Commands
  class BuildCommand < ProjectCommand
    def arguments_schema
      [ Arguments::Treeish.new ]
    end

    def description
      "Checks out and builds the specified version of the git repository for #{projects}."
    end

    def run_on_project(project, treeish)
      project.fetch
      project.checkout(treeish)
      project.build
    end
  end
end
