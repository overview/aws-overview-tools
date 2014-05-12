require_relative 'base'
require_relative '../machine_type'

module Stores
  class MachineTypes < Base
    def self.item_type; MachineType end
  end
end
