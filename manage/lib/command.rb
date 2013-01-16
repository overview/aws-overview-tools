class Command
  def name
    raise NotImplementedError.new
  end

  def arguments_schema
    raise NotImplementedError.new
  end

  def description
    raise NotImplementedError.new
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
