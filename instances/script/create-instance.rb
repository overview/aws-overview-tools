#!/usr/bin/env ruby

require 'trollop'

opts = Trollop::options do
  opt(:type, 'Instance type')
end
