require_relative 'instance'
require_relative 'searcher'

class InstanceCollection
  include Enumerable

  def initialize(list)
    if list.empty? || list.first.is_a?(Hash)
      @instances = list.map{ |hash| Instance.new(hash) }
    else
      @instances = list
    end
  end

  def empty?
    @instances.empty?
  end

  def each(&block)
    @instances.each(&block)
  end

  def <<(instance)
    searcher = Searcher.new(instance)
    if with_searcher(searcher).first.nil?
      @instances << Instance.new({
        'env' => instance.env,
        'type' => instance.type,
        'ip_address' => instance.ip_address
      })
      @instances = @instances.sort_by { |instance| [ instance.env, instance.type, instance.ip_address ] }
    end
  end

  def remove(instance)
    searcher = Searcher.new(instance)
    real_instance = with_searcher(searcher).first
    @instances.delete(real_instance) if real_instance
  end

  def with_env(env)
    InstanceCollection.new(@instances.select { |instance| instance.env == env })
  end

  def with_type(type)
    InstanceCollection.new(@instances.select { |instance| instance.type == type })
  end

  def with_ip_address(ip_address)
    InstanceCollection.new(@instances.select { |instance| instance.ip_address == ip_address })
  end

  def with_searcher(searcher)
    ret = with_env(searcher.env)
    if searcher.type
      ret = ret.with_type(searcher.type)
    end
    if searcher.ip_address
      ret = ret.with_ip_address(searcher.ip_address)
    end
    ret
  end

  def encode_with(coder)
    coder.represent_seq(nil, @instances)
  end
end
