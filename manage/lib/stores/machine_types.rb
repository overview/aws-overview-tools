require 'machine_type'

require 'stores/base'

module Stores
  class MachineTypes < Base
    def self.item_type; MachineType end
  end
end
