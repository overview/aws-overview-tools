#!/usr/bin/env ruby

require 'tempfile'

require 'aws'
require 'net/ssh'

USERNAME='ubuntu'

class SshRunner
  def initialize(session)
    @session = session
  end

  def log(label, message)
    puts "[#{label.upcase}] #{message}"
  end

  def exec(command)
    log('run', command)

    status = nil

    @session.open_channel do |channel|
      channel.exec(command) do |ch, success|
        if success
          ch.on_data do |ch2, data|
            log('stdout', data)
          end

          ch.on_extended_data do |ch2, type, data|
            log('stderr', data)
          end

          ch.on_request('exit-status') do |ch, data|
            status = data.read_long
          end
        else
          raise Exception.new("Command could not be executed")
        end
      end
    end

    @session.loop { status.nil? }

    msg = "Command exited with status #{status}"
    if status != 0
      raise Exception.new(msg)
    else
      log('run', msg)
    end
  end
end

class AwsImage
  attr_reader(:ec2_image)

  def initialize(ec2_image_or_options)
    if ec2_image_or_options.respond_to?(:id)
      @ec2_image = ec2_image_or_options
    else
      @options = {}.merge(ec2_image_or_options)
    end
  end

  def username
    USERNAME
  end

  def ami_id
    ec2_image && ec2_image.id || nil
  end

  def find_ec2_image
    @ec2_image = AWS::EC2.new.regions[region].images
      .with_owner('self')
      .filter('name', type_tag)
      .first
  end

  def region
    ec2_image && ec2_image.location || @options[:region]
  end

  def arch
    ec2_image && ec2_image.architecture || @options[:arch]
  end

  def type_tag
    self.class.type_tag
  end

  def created!
    if ec2_image = find_ec2_image
      self.class.new(ec2_image)
    else
      create!
    end
  end

  def create!
    instance = VanillaAwsInstance.new(:zone => "#{region}a", :arch => arch).create!
    build!(instance)
  end

  def build!(ec2_instance)
    if (status = ec2_instance.status) != :running
      puts "Instance status is '#{status}'. Waiting until it is 'running'..."
      sleep 1 while ec2_instance.status != :running
    end

    puts "Waiting for SSH to respond (with 5-second timeout)..."
    begin
      Net::SSH.start(ec2_instance.ip_address, username, :timeout => 5) {}
    rescue Timeout::Error
      retry
    rescue Errno::ECONNREFUSED
      retry
    end

    puts "Running creation commands..."

    Net::SSH.start(ec2_instance.ip_address, username) do |session|
      ssh = SshRunner.new(session)
      run_ssh_commands(ssh)
    end

    image = ec2_instance.create_image(self.class.type_tag)
    self.class.new(image)
  end

  def run_ssh_commands(ssh)
    ssh.exec("sudo perl -pi -e 's/# *(.* universe)$/$1/' /etc/apt/sources.list")
    ssh.exec("sudo apt-get -q update")
    ssh.exec("sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y dist-upgrade")
    # I don't know why, but we seem to need to do this again. (Is it because GPG updates?)
    ssh.exec("sudo apt-get -q update")
    ssh.exec("sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y dist-upgrade")
    if !packages.empty?
      ssh.exec("sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y install #{packages.join(' ')}")
    end
  end

  def base_ami_id
    @base_ami_id ||= find_base_ami_id
  end

  def packages
    []
  end
end
