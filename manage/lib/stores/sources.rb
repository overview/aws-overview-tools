require_relative 'base'
require_relative '../source'

module Stores
  class Sources < Base
    def self.item_type; Source end
  end
end
