require 'net/ssh'

require_relative './machine_shell'

class Machine
  attr_reader(:environment, :ip_address, :type)

  def initialize(hash)
    @environment = hash['environment'] || hash[:environment]
    @ip_address = hash['ip_address'] || hash[:ip_address]
    @type = hash['type'] || hash[:type]
  end

  def to_s
    "#{environment}/#{type.name}/#{ip_address}"
  end

  def start_commands; type.start_commands; end
  def stop_commands; type.stop_commands; end
  def restart_commands; type.restart_commands; end

  def shell(&block)
    return block.call(@shell) if @shell

    ssh = Net::SSH.start(ip_address, 'ubuntu') # we'll disconnect on shutdown
    @shell = MachineShell.new(ssh)

    block.call(@shell)
  end
end
