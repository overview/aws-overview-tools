module CommandExecutors
  class CommandFailedException < Exception
    def initialize(message)
      super(message)
    end
  end

  # Executes commands on a shell.
  #
  # overview-manage needs to run commands, both locally and on remote machines.
  # This class defines the common part.
  class Base
    # Executes an arbitrary command on the remote server.
    #
    # Make sure the command is properly escaped: use Shellwords to make it that
    # way.
    #
    # Each command executes in its own environment; a CommandExecutor does not
    # remember its current working directory.
    #
    # Side-effects: aside from the side-effects of the command itself,
    # implementations should log progress and status codes.
    #
    # Return value: on success, implementations should return the contents of
    # stdout. (They should log stderr as errors.) This is always truthy.
    #
    # If the command cannot be executed, raise a RuntimeError. If the command
    # exits with a non-zero status code, raise a CommandFailedException.
    def exec_command(command)
    end
  end
end
