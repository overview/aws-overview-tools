require 'base64'
require 'socket'

require_relative 'log'

class RemoteBuilder
  attr_reader(
    :ami_id,
    :availability_zone,
    :build_init_commands,
    :user_data,
    :cache_volume_id,
    :ec2,
    :instance_type,
    :keypair_name,
    :security_group_id,
    :subnet_id,
    :vpc_id
  )

  def initialize(ec2, hash)
    @ec2 = ec2
    @availability_zone = hash[:availability_zone] || hash['availability_zone']
    @security_group_id = hash[:security_group_id] || hash['security_group_id']
    @subnet_id = hash[:subnet_id] || hash['subnet_id']
    @vpc_id = hash[:vpc_id] || hash['vpc_id']
    @user_data = hash[:user_data] || hash['user_data']
    @instance_type = hash[:instance_type] || hash['instance_type']
    @ami_id = hash[:ami_id] || hash['ami_id']
    @cache_volume_id = hash[:cache_volume_id] || hash['cache_volume_id']
    @keypair_name = hash[:keypair_name] || hash['keypair_name']
    @pause_duration = hash[:pause_duration] || hash['pause_duration'] || 1
    @build_init_commands = hash[:init_commands] || hash['init_commands'] || 1
  end

  # Runs the given block with two parameters: an AWS::EC2::Instance and a
  # MachineShell.
  #
  # The build environment has these properties:
  #
  # * ~/.sbt, ~/.ivy2 and ~/.npm are cached on a volume specified by
  #   `cache_volume_id`
  # * `build` is a SSD-backed directory. It's fast.
  # * `build/` contains the contents of the Source's `archive.tar.gz`.
  #
  # When this block exits, the instance is spun down.
  #
  # Every time you call this block, it costs a bit of money. We spin down the
  # EC2 instance even if the block fails.
  def with_instance(&block)
    instance = nil

    $log.info('remote-builder') { "Creating instance" }
    reservation = @ec2.run_instances(
      min_count: 1,
      max_count: 1,
      image_id: ami_id,
      placement: { availability_zone: availability_zone },
      security_group_ids: [ security_group_id ],
      subnet_id: subnet_id,
      instance_type: instance_type,
      instance_initiated_shutdown_behavior: 'terminate',
      user_data: Base64.encode64(@user_data),
      key_name: keypair_name,
      block_device_mappings: [{
        device_name: '/dev/sdf',
        virtual_name: 'ephemeral0'
      }]
    ).data
    instance = reservation[:instances][0]
    $log.info('remote-builder') { "Waiting for instance #{instance[:instance_id]} to start up..." }
    @ec2.wait_until(:instance_running, instance_ids: [ instance[:instance_id] ])

    $log.info('remote-builder') { "Attaching #{cache_volume_id} to instance #{instance[:instance_id]}" }
    volume = @ec2.attach_volume(
      volume_id: cache_volume_id,
      instance_id: instance[:instance_id],
      device: 'xvdg'
    ).data
    @ec2.wait_until(:volume_in_use, volume_ids: [ cache_volume_id ])

    $log.info('remote-builder') { "Waiting for #{instance[:instance_id]} to respond on port 22" }
    ip_address = @ec2.describe_instances(instance_ids: [ instance[:instance_id] ])
      .data[:reservations][0][:instances][0][:private_ip_address]
    $log.info('remote-builder') { "IP address is #{ip_address}" }
    nil while !can_connect_on_port_22?(ip_address)

    with_machine_shell(ip_address) do |machine_shell|
      $log.info('remote-builder') { "Waiting for initialization to finish" }
      while !machine_shell.exec('test -f /run/cloud-init/result.json')
        sleep(1)
      end

      $log.info('remote-builder') { "Setting up build environment" }
      for command in build_init_commands
        machine_shell.exec(command)
      end
      yield(instance, machine_shell)
    end

  ensure
    if instance
      $log.info('remote-builder') { "Terminating #{instance[:instance_id]}" }
      @ec2.terminate_instances(instance_ids: [ instance[:instance_id] ])
    end
  end

  def build(source_archive_path, build_commands, destination_archive_path)
    with_instance do |instance, machine_shell|
      machine_shell.upload_r(source_archive_path, 'archive.tar.gz')
      machine_shell.exec('cd build && tar zxf ../archive.tar.gz')

      for command in build_commands
        machine_shell.exec("cd build && #{command}")
      end

      machine_shell.download('build/archive.zip', destination_archive_path)
      machine_shell.md5sum('build/archive.zip')
    end
  end

  protected

  def with_machine_shell(ip_address, &block)
    Net::SSH.start(ip_address, 'ubuntu', paranoid: false) do |ssh|
      machine_shell = MachineShell.new(ssh)
      yield(machine_shell)
    end
  end

  def can_connect_on_port_22?(ip_address)
    socket = TCPSocket.new(ip_address, 22) rescue false
    socket.close if socket
    !!socket
  end

  def pause
    sleep @pause_duration
  end
end
