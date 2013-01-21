require 'yaml'
require 'yaml/store'

class ManagerConfig
  def initialize(filename)
    @store = YAML::Store.new(filename)
  end

  def [](key)
    @store.transaction(true) do
      @store[key.to_s]
    end
  end

  def method_missing(method, *args, &block)
    self[method]
  end
end
