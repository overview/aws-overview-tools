require 'socket'

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
    $log.info('remote-builder') { "Creating instance" }
    instance = @ec2.instances.create(
      availability_zone: availability_zone,
      image_id: ami_id,
      security_groups: security_group,
      instance_type: instance_type,
      instance_initiated_shutdown_behavior: 'terminate',
      key_name: keypair_name,
      block_device_mappings: [{
        device_name: '/dev/sde',
        virtual_name: 'ephemeral0'
      },
      {
        device_name: '/dev/sdf',
        virtual_name: 'ephemeral1'
      }]
    )
    pause while instance.status != :running

    $log.info('remote-builder') { "Attaching #{cache_volume_id} to instance #{instance.id}" }
    volume = @ec2.volumes[cache_volume_id]
    attachment = volume.attach_to(instance, '/dev/sdg')
    pause while attachment.status != :attached

    $log.info('remote-builder') { "Waiting for #{instance.id} to respond on port 22" }
    pause while !instance.private_ip_address
    nil while !can_connect_on_port_22?(instance.private_ip_address)

    with_machine_shell(instance.private_ip_address) do |machine_shell|
      $log.info('remote-builder') { "Setting up build environment" }
      # build-cache persists between builds, so we don't need to download tons
      # of dependencies from really slow servers.
      machine_shell.exec('mkdir -p build-cache && sudo mount /dev/xvdg build-cache && ln -sf `pwd`/build-cache/.ivy2 . && ln -sf `pwd`/build-cache/.npm . && ln -sf `pwd`/build-cache/.sbt .')
      # ephemeral0 and ephemeral1 are SSD-backed, making them fast
      machine_shell.exec('sudo umount /dev/xvde && sudo mkswap -f /dev/xvde && sudo swapon /dev/xvde')
      machine_shell.exec('mkdir -p build && sudo mkfs.ext2 /dev/xvdf && sudo mount /dev/xvdf build && sudo chown ubuntu:ubuntu build')

      yield(instance, machine_shell)
    end

  ensure
    instance.terminate
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
    Net::SSH.start(ip_address, 'ubuntu') do |ssh|
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
