require_relative 'project'

class ProjectCollection
  attr_reader(:config)

  def initialize(config)
    @config = config
  end

  def [](key)
    if options = @config.projects[key]
      Project.new(config, key, options)
    else
      raise RuntimeException.new("Project #{key} is not in config.yml")
    end
  end

end
