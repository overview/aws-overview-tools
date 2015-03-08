require_relative 'stores/sources'
require_relative 'stores/machine_types'

class Store
  attr_reader(:machine_types, :sources)

  def initialize(machine_types, sources)
    @machine_types = machine_types
    @sources = sources
  end

  def self.from_yaml(yaml)
    machine_types = Stores::MachineTypes.from_yaml(yaml['machine_types'])
    sources = Stores::Sources.from_yaml(yaml['sources'])
    self.new(machine_types, sources)
  end
end
