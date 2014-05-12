require 'logger'
require 'log'

RSpec.configure do |config|
  $log.level = Logger::ERROR
end
