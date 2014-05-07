require 'net/ssh'

require 'machine_shell'

class Machine
  attr_reader(:environment, :type, :ip_address)

  def initialize(hash_or_instance)
    if hash_or_instance.is_a?(Hash)
      @environment = hash_or_instance['environment'] || hash_or_instance[:environment]
      @type = hash_or_instance['type'] || hash_or_instance[:type]
      @ip_address = hash_or_instance['ip_address'] || hash_or_instance[:ip_address]
    else
      @environment = hash_or_instance.environment
      @type = hash_or_instance.type
      @ip_address = hash_or_instance.ip_address
    end
  end

  def to_s
    "#{environment}.#{type}.#{ip_address}"
  end

  def to_hash
    {
      'environment' => environment,
      'type' => type,
      'ip_address' => ip_address
    }
  end

  def encode_with(coder)
    coder.represent_map(nil, to_hash)
  end

  def shell(&block)
    return block.call(@shell) if @shell

    ssh = Net::SSH.start(ip_address, 'ubuntu') # we'll disconnect on shutdown
    @shell = MachineShell.new(ssh)

    block.call(@shell)
  end
end
