require_relative 'repository'

class RepositoryCollection
  attr_reader(:config)

  def initialize(config)
    @config = config
  end

  def [](key)
    if options = @config.repositories[key]
      Repository.new(config, key, options)
    else
      raise RuntimeException.new("Repository #{key} is not in config.yml")
    end
  end
end
