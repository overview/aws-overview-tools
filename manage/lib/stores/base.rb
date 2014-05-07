module Stores
  class Base
    def initialize(items)
      @items = items
    end

    def self.from_yaml(yaml)
      items = yaml.map { |name, subyaml| self.item_type.from_yaml(name, subyaml) }
      self.new(items)
    end

    def [](key)
      index = @items.find_index { |item| item.name == key }
      index && @items[index]
    end
  end
end
