class Command
  def name
    raise NotImplementedError.new
  end
  def self.name(name)
    define_method(:name) do
      name
    end
  end

  def arguments_schema
    raise NotImplementedError.new
  end
  def self.arguments_schema(schema)
    define_method(:arguments_schema) do
      schema
    end
  end

  def description
    raise NotImplementedError.new
  end
  def self.description(description)
    define_method(:description) do
      description
    end
  end

  def run(runner, *args)
    raise NotImplementedError.new
  end

  def usage
    ret = "Usage: #{$0} #{name} #{arguments_schema.map(&:name).join(' ')}\n"
    if arguments_schema.length
      ret << "\nWhere:"
      arguments_schema.each do |argument|
        ret << "\n    #{argument.name} #{argument.description}"
      end
    end
    ret
  end
end
