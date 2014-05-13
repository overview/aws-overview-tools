require 'shellwords'
require 'net/scp'

require_relative 'log'

# An SSH connection to a Machine, with only a few hard-coded commands.
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

  # Deletes all files in a given path.
  #
  # Returns true if the deletion worked (even if the files did not exist).
  # Returns false for, say, permission errors.
  def rm_rf(path)
    exec([ 'rm', '-rf', path ])
  end

  # Links src to dest, such that dest is a symlink pointing at src.
  #
  # Returns true if the linking worked. Returns false for, say, permission
  # errors.
  def ln_sf(src, dest)
    exec([ 'ln', '-sf', src, dest ])
  end

  # Creates all directories in the given path.
  #
  # Returns true if the creation worked (even if the path already existed).
  # Returns false for, say, permission errors.
  def mkdir_p(path)
    exec([ 'mkdir', '-p', path ])
  end

  # Returns true if the given path is a valid ComponentArtifact.
  #
  # This doesn't test if extra files have been injected in the Artifact: this
  # is an error we don't expect. It _does_ test if any files are missing or
  # corrupt, which is far more likely (because of an aborted upload).
  def is_component_artifact_valid?(path)
    exec("(cd #{Shellwords.escape(path)}/files && md5sum --status -c ../md5sum.txt)")
  rescue CommandFailedException
    false
  end

  # Copies the file or directory rooted at local_path into a new file or
  # directory, remote_path, on the remote machine.
  #
  # For instance: `upload_r('/tmp/foo', '/usr/local/foo')` will behave like
  # `scp -r /tmp/foo/* user@host:/usr/local/foo`.
  #
  # If you are copying a directory, the remote_path must exist; it should
  # probably be empty, too.
  #
  # This method always returns true; a failure will cause a stack trace.
  def upload_r(local_path, remote_path)
    $log.info(@ssh.host) { "Uploading #{local_path} to #{remote_path}" }
    ssh.scp.upload!(local_path, remote_path, recursive: true)
    true
  end

  # Copies the file or directory rooted at remote_path into a new file or
  # directory, local_path, on the local machine.
  #
  # For instance: `download_r('/usr/local/foo', '/tmp/foo')` will behave like
  # `scp -r user@host:/usr/local/foo /tmp/foo`.
  #
  # This method always returns true; a failure will cause a stack trace.
  def download_r(remote_path, local_path)
    $log.info(@ssh.host) { "Downloading #{remote_path} to #{local_path}" }
    ssh.scp.download!(remote_path, local_path, recursive: true)
    true
  end

  # Runs md5sum on the host and returns the MD5 sum.
  def md5sum(path)
    command = "md5sum -b #{Shellwords.escape(path)}"
    $log.info(@ssh.host) { command }
    ret = ssh.exec!(command)

    md5 = ret
      .downcase
      .lines
      .grep(/^[0-9a-z]{32}/)
      .map{ |line| line[0...32] }
      .first

    if md5
      md5
    else
      raise CommandFailedException.new(ret.strip)
    end
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

  private

  def exec_command(command)
    $log.info(@ssh.host) { "Running #{command}" }

    status = nil

    @ssh.open_channel do |channel|
      channel.exec(command) do |ch, success|
        if success
          ch.on_data do |ch2, data|
            $log.info(@ssh.host) { data }
          end

          ch.on_extended_data do |ch2, type, data|
            $log.warn(@ssh.host) { data }
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
      true
    end
  end
end
