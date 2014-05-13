require_relative 'log'

class RemoteBuilder
  attr_reader(
    :ami_id,
    :availability_zone,
    :cache_volume_id,
    :ec2,
    :instance_type,
    :keypair_name,
    :security_group
  )

  def initialize(ec2, hash)
    @ec2 = ec2
    @availability_zone = hash[:availability_zone] || hash['availability_zone']
    @security_group = hash[:security_group] || hash['security_group']
    @instance_type = hash[:instance_type] || hash['instance_type']
    @ami_id = hash[:ami_id] || hash['ami_id']
    @cache_volume_id = hash[:cache_volume_id] || hash['cache_volume_id']
    @keypair_name = hash[:keypair_name] || hash['keypair_name']
    @pause_duration = hash[:pause_duration] || hash['pause_duration'] || 1
  end

  def with_instance(&block)
    instance = @ec2.instances.create(
      availability_zone: availability_zone,
      image_id: ami_id,
      security_groups: security_group,
      instance_type: instance_type,
      instance_initiated_shutdown_behavior: 'terminate',
      key_name: keypair_name,
      block_device_mappings: [{
        virtual_name: cache_volume_id,
        device_name: '/dev/sdf'
      }]
    )

    $log.info('remote-builder') { "Waiting for #{instance} to get an IP address" }
    pause while !instance.private_ip_address

    $log.info('remote-builder') { "Waiting for #{instance} to respond on port 22" }
    nil while !can_connect_on_port_22?(instance.private_ip_address)

    with_machine_shell(instance.private_ip_address) do |machine_shell|
      yield(instance, machine_shell)
    end

    instance.terminate
  end

  def build(source_archive_path, build_commands, destination_archive_path)
    with_instance do |instance, machine_shell|
      machine_shell.upload_r(source_archive_path, 'archive.tar.gz')
      machine_shell.mkdir_p('build')
      machine_shell.exec([ 'cd', 'build' ])
      machine_shell.exec([ 'unzip', '../archive.tar.gz' ])

      for command in build_commands
        machine_shell.exec(command)
      end

      machine_shell.download_r('archive.zip', destination_archive_path)
      machine_shell.md5sum('archive.zip')
    end
  end

  protected

  def with_machine_shell(ip_address, &block)
    Net::SSH.start(ip_address, 'ubuntu') do |ssh|
      machine_shell = MachineShell.new(ssh)
      yield(machine_shell)
    end
  end

  def can_connect_on_port_22?(ip_address)
    timeout = @pause_duration
    timeout = 1 if timeout < 0

    socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    address = Socket.sockaddr_in(22, ip_address)

    begin
      socket.connect_nonblock(address)
      true
    rescue IO::WaitWritable
      IO.select(nil, [socket], nil, timeout) # wait up to the timeout
      begin
        socket.connect_nonblock(address)     # check the connection
        true
      rescue Errno::EISCONN
        false
      end
    end
  end

  def pause
    sleep @pause_duration
  end
end
