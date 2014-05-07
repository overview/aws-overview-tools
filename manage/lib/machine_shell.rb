require 'shellwords'

require 'net/scp'

# An SSH connection to a Machine, with only a few hard-coded commands.
class MachineShell
  attr_reader(:ssh) # a Net::SSH::Session

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
    exec("(cd #{Shellwords.escape(path)}/files && md5sum -c ../md5sum.txt)")
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
    ssh.scp.upload!(local_path, remote_path, recursive: true)
    true
  end

  private

  def exec(args)
    cmd = if args.kind_of?(Array)
      Shellwords.join(args)
    else
      args
    end

    result = ssh.exec!(cmd + ' > /dev/null 2>&1; echo $?')
    success = (result.strip == '0')
  end
end
