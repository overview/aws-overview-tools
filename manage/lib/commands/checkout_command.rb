require_relative '../arguments/treeish'
require_relative '../project_command'

module Commands
  class CheckoutCommand < ProjectCommand
    def arguments_schema
      [ Arguments::Treeish.new ]
    end

    def description
      "Checks out the specified version of git repository for processing for #{projects}."
    end

    def run_on_project(project, treeish)
      project.fetch
      project.checkout(treeish)
    end
  end
end
