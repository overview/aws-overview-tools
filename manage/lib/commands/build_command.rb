require_relative '../command'

module Commands
  class BuildCommand < Command
    def arguments_schema
      [ Arguments::Treeish.new ]
    end

    def project_names
      raise NoMethodError.new
    end

    def description
      "Checks out and builds the specified version of the #{project} git repository."
    end

    def run(runner, treeish)
      project_names.each do |p|
        project = runner.projects[p]
        project.fetch
        project.checkout(treeish)
        project.build
      end
    end
  end
end
