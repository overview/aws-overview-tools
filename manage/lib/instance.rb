class Instance
  attr_reader(:env, :type, :ip_address)

  def initialize(hash_or_instance)
    if hash_or_instance.is_a?(Hash)
      @env = hash_or_instance['env']
      @type = hash_or_instance['type']
      @ip_address = hash_or_instance['ip_address']
    else
      @env = hash_or_instance.env
      @type = hash_or_instance.type
      @ip_address = hash_or_instance.ip_address
    end
  end

  def to_s
    "#{env}.#{type}.#{ip_address}"
  end

  def to_hash
    {
      'env' => env,
      'type' => type,
      'ip_address' => ip_address
    }
  end

  def encode_with(coder)
    coder.represent_map(nil, to_hash)
  end
end
