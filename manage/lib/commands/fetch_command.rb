require_relative '../project_command'

module Commands
  class FetchCommand < ProjectCommand
    def arguments_schema
      []
    end

    def description
      "Updates the managed git repository for #{projects}"
    end

    def run_on_project(project)
      project.fetch
    end
  end
end
