class Argument
  # A short name for the argument. For instance: 'INSTANCE'
  #
  # Optional names should look like '[INSTANCE]'
  #
  # This is the name that will appear in command-line help
  def name
    raise NotImplementedError.new
  end

  # A description of the argument, in verb-object format.
  #
  # For instance: "specifies a particular instance (e.g.,
  # 'production.web.10.1.2.3')"
  def description
    raise NotImplementedError.new
  end

  # Parses the command-line string and returns the proper value.
  #
  # Throws an exception if the string is of the wrong format.
  def parse(runner, string)
    raise NotImplementedError.new
  end
end
