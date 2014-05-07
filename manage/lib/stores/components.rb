require 'component'

require 'stores/base'

module Stores
  class Components < Base
    def self.item_type; Component end
  end
end
