require_relative '../project_command'

module Commands
  class CleanCommand < ProjectCommand
    def arguments_schema
      []
    end

    def description
      "Cleans the directory for #{projects}"
    end

    def run_on_project(project)
      project.clean
    end

  end
end
