require 'component'

require 'stores/base'

module Stores
  class Components < Base
    def self.item_type; Component end

    def with_source(source_name)
      @items.select { |i| i.source == source_name }
    end
  end
end
