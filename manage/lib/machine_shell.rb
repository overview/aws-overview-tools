require 'shellwords'
require 'net/scp'

require_relative 'log'
require_relative 'command_executors/base'
require_relative 'command_executors/local'
require_relative 'command_executors/ssh'

# Something that runs commands.
#
# If initialized with a Net::SSH::Session, the commands will run remotely.
# Otherwise, the commands will run on this computer.
class MachineShell
  attr_reader(:ssh) # a Net::SSH::Session

  def initialize(ssh = nil)
    @ssh = ssh
    @command_executor = if @ssh
      CommandExecutors::Ssh.new(@ssh)
    else
      CommandExecutors::Local.new
    end
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
  def ln_sfT(src, dest)
    exec([ 'ln', '-sfT', src, dest ])
  end

  # Returns the full path of the symlink, "path".
  def readlink(path)
    exec([ 'readlink', path ])
  rescue CommandExecutors::CommandFailedException => e
    nil
  end

  # Creates all directories in the given path.
  #
  # Returns true if the creation worked (even if the path already existed).
  # Returns false for, say, permission errors.
  def mkdir_p(path)
    exec([ 'mkdir', '-p', path ])
  end

  # Copies the directory rooted at local_path into a new directory,
  # remote_path, on the remote machine.
  #
  # For instance: `upload_r('/tmp/foo', '/usr/local/foo')` will behave like
  # `scp -r /tmp/foo/* user@host:/usr/local/foo`.
  #
  # The remote_path must exist; it should probably be empty, too.
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
  # For instance: `download('/usr/local/foo.txt', '/tmp/foo.txt')` will behave
  # like `scp -r user@host:/usr/local/foo.txt /tmp/foo.txt`.
  #
  # This method always returns true; a failure will cause a stack trace.
  def download(remote_path, local_path)
    $log.info(@ssh.host) { "Downloading #{remote_path} to #{local_path}" }
    ssh.scp.download!(remote_path, local_path)
    true
  end

  # Runs md5sum on the host and returns the MD5 sum.
  def md5sum(path)
    ret = exec([ 'md5sum', '-b', path ])
    md5 = ret
      .downcase
      .lines
      .grep(/^[0-9a-z]{32}/)
      .map{ |line| line[0...32] }
      .first

    if md5
      md5
    else
      raise CommandExecutors::CommandFailedException.new(ret.strip)
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

  protected

  def exec_command(command)
    @command_executor.exec_command(command)
  end
end
