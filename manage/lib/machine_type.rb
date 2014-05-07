class MachineType
  attr_reader(:name, :components)

  def initialize(name, components)
    @name = name
    @components = components
  end

  def self.from_yaml(name, yaml)
    MachineType.new(name, yaml['components'] || [])
  end
end
