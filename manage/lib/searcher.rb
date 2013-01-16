# Specifies a "search"
#
# A search looks like this:
#
# * "production": all instances in production
# * "staging.web": all web instances in staging
# * "production.worker.10.1.2.3": a specific instance
#
# The "env" part is mandatory, and you cannot specify an IP address without
# specifying the others. (Rationale: we want to avoid typos and unexpected
# behavior.)
class Searcher
  attr_reader(:env, :type, :ip_address)

  def initialize(string_or_list)
    if string_or_list.nil? || (string_or_list.respond_to?(:empty?) && string_or_list.empty?)
      raise ArgumentError.new("Empty searcher specification")
    elsif string_or_list.respond_to?(:to_list)
      string_or_list = string_or_list.to_list
    elsif string_or_list.respond_to?(:upcase)
      string_or_list = string_or_list.split('.', 3)
    end

    @env = string_or_list[0]
    @type = string_or_list[1]
    @ip_address = string_or_list[2]
  end

  def to_list
    ret = [ env ]
    if !type.nil?
      ret << type
    end
    if !ip_address.nil?
      ret << ip_address
    end
    ret
  end
end
