require 'shellwords'

require_relative 'log'

# Something that runs commands through a Net::SSH::Session.
class MachineShell
  attr_reader(:ssh) # a Net::SSH::Session

  class CommandFailedException < Exception
    def initialize(message)
      super(message)
    end
  end

  def initialize(ssh)
    @ssh = ssh
  end

  # Executes an arbitrary command on the remote server.
  #
  # Either pass an Array of Strings (preferred), or pass one big string.
  def exec(args)
    cmd = if args.kind_of?(Array)
      Shellwords.join(args)
    else
      args
    end

    exec_command(cmd)
  end

  protected

  def exec_command(command)
    $log.info(@ssh.host) { "Running #{command}" }

    output = ""
    status = nil

    @ssh.open_channel do |channel|
      channel.exec(command) do |ch, success|
        if success
          ch.on_data do |ch2, data|
            data.lines.each do |line|
              $log.info(@ssh.host) { line.chomp }
              output << line
            end
          end

          ch.on_extended_data do |ch2, type, data|
            data.lines.each do |line|
              $log.warn(@ssh.host) { line.chomp }
            end
          end

          ch.on_request('exit-status') do |ch, data|
            status = data.read_long
          end
        else
          raise RuntimeError.new("Command could not be executed")
        end
      end
    end

    @ssh.loop { status.nil? }

    msg = "Command exited with status #{status}"
    if status != 0
      raise CommandFailedException.new(msg)
    else
      $log.info(@ssh.host) { msg }
      output
    end
  end
end
