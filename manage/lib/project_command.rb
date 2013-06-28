class ProjectCommand < Command

  def project_names
    raise NoMethodError.new
  end

  def run_on_project(project, *args)
    raise NoMethodError.new
  end

  def projects
    project_names.join(', ')
  end

  def run(runner, *args)
    project_names.each do |p|
      project = runner.projects[p]
      run_on_project(project, *args)
    end
  end
end
