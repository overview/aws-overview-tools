require_relative 'commands/help'
require_relative 'commands/status'
require_relative 'commands/add_instance'
require_relative 'commands/remove_instance'
require_relative 'commands/build_command'
require_relative 'commands/prepare_command'
require_relative 'commands/publish_command'
require_relative 'commands/install_command'
require_relative 'commands/deploy_command'
#require_relative 'commands/restart'
#require_relative 'commands/start'
#require_relative 'commands/stop'
require_relative 'machine'

class Runner
  attr_reader(:state, :commands)

  def initialize(state, store)
    @state = state
    @store = store

    command_classes = [
      Commands::Help,
      Commands::Status,
      Commands::AddInstance,
      Commands::RemoveInstance,
      Commands::BuildCommand,
      Commands::PrepareCommand,
      Commands::PublishCommand,
      Commands::InstallCommand,
      Commands::DeployCommand
    ]

    # Turn into hash of { 'add-instance' => Commands::AddInstance.new }
    @commands = command_classes.map(&:new).inject({}) { |h, v| h[v.name] = v; h }
  end

  def usage
    "Usage: #{$0} COMMAND [ARG1...]\n\n" +
    "Where COMMAND is one of: #{@commands.keys.sort.join(' ')}\n\n" +
    "Type \"#{$0} help COMMAND\" for help with a command"
  end

  # Deprecated
  def instances
    @state.instances
  end

  def machines
    @machines ||= @state.instances.map do |instance|
      type = @store.machine_types[instance.type]
      Machine.new(
        environment: instance.env,
        ip_address: instance.ip_address,
        type: instance.type,
        components: Set.new(type.components)
      )
    end
  end

  def machines_with_spec(spec)
    raise ArgumentError.new("You must specify some machines. Try 'production/web' or 'staging/worker/10.1.2.3'") if spec.empty?

    environment, type, ip_address = spec.split('/', 3)

    machines
      .select{ |m| m.environment == environment }
      .select{ |m| type.nil? || m.type == type }
      .select{ |m| ip_address.nil? || m.ip_address == ip_address }
  end

  def components
    @store.components
  end

  def components_with_source(source)
    components.with_source(source)
  end

  def machine_types
    @store.machine_types
  end

  def sources
    @store.sources
  end

  def environments
    @environments ||= Set.new(
      machines
        .map{ |m| m.environment }
        .uniq
    )
  end

  def run(command_name, *args)
    command = @commands[command_name]
    if !command
      $stderr.puts "Invalid command '#{command_name}'.\n\n"
      $stderr.puts "Valid commands:\n#{@commands.keys.sort.map{|s| "    #{s}"}.join("\n")}"
      exit(1)
    end

    begin
      arguments = parse_args_with_schema(args, command.arguments_schema)
    rescue ArgumentError => e
      $stderr.puts "Invalid arguments for command #{command.name}: #{e.message}.\n\n"
      $stderr.puts command.usage
      exit(1)
    end
    command.run(self, *arguments)
  end

  def parse_args_with_schema(args, schema)
    schema.zip(args).map do |argument, string|
      argument.parse(self, string)
    end
  end
end
