require_relative '../command'

module Commands
  class CleanCommand < Command
    def arguments_schema
      []
    end

    def project_names
      raise NoMethodError.new
    end

    def description
      "Cleans the #{repository} directory, assuming it exists."
    end

    def run(runner)
      project_names.each do |p| 
        project = runner.projects[p]
        project.clean
      end
    end
  end
end
