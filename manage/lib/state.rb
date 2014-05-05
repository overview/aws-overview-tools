require 'yaml'
require 'yaml/store'

require_relative 'instance_collection'

# Stores system state between runs
class State
  attr_reader(:instances)

  def initialize(filename)
    @store = YAML::Store.new(filename)
    @store.transaction(true) do
      @instances = InstanceCollection.new(@store.fetch('instances', []))
    end
  end

  def save
    @store.transaction do
      @store['instances'] = @instances
    end
  end
end
