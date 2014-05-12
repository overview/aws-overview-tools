require_relative 'base'
require_relative '../component'

module Stores
  class Components < Base
    def self.item_type; Component end

    def with_source(source_name)
      @items.select { |i| i.source == source_name }
    end
  end
end
