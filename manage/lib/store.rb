require 'stores/components'
require 'stores/sources'
require 'stores/machine_types'

class Store
  attr_reader(:components, :machine_types, :sources)

  def initialize(components, machine_types, sources)
    @components = components
    @machine_types = machine_types
    @sources = sources
  end

  def self.from_yaml(yaml)
    components = Stores::Components.from_yaml(yaml['components'])
    machine_types = Stores::MachineTypes.from_yaml(yaml['machine_types'])
    sources = Stores::Sources.from_yaml(yaml['sources'])
    self.new(components, machine_types, sources)
  end
end
