require_relative 'commands/add_instance'
require_relative 'commands/help'
require_relative 'commands/remove_instance'
require_relative 'commands/status'
require_relative 'commands/fetch'
require_relative 'commands/fetch_config'
require_relative 'commands/checkout'
require_relative 'commands/checkout_config'
require_relative 'commands/build'
require_relative 'commands/build_config'
require_relative 'commands/clean'
require_relative 'commands/clean_config'
require_relative 'commands/copy'
require_relative 'commands/copy_config'
require_relative 'commands/deploy'
require_relative 'commands/deploy_config'
require_relative 'commands/restart'
require_relative 'commands/start'
require_relative 'commands/stop'

class Runner
  attr_reader(:state, :commands)

  def initialize(state, store)
    @state = state
    @store = store

    command_classes = [
      Commands::Status,
      Commands::AddInstance,
      Commands::RemoveInstance,
      Commands::Help,
      Commands::Build,
      Commands::BuildConfig,
      Commands::Clean,
      Commands::CleanConfig,
      Commands::Fetch,
      Commands::FetchConfig,
      Commands::Checkout,
      Commands::CheckoutConfig,
      Commands::Copy,
      Commands::CopyConfig,
      Commands::Deploy,
      Commands::DeployConfig,
      Commands::Restart,
      Commands::Start,
      Commands::Stop
    ]

    # Turn into hash of { 'add-instance' => Commands::AddInstance.new }
    @commands = command_classes.map(&:new).inject({}) { |h, v| h[v.name] = v; h }
  end

  def usage
    "Usage: #{$0} COMMAND [ARG1...]\n\n" +
    "Where COMMAND is one of: #{@commands.keys.sort.join(' ')}\n\n" +
    "Type \"#{$0} help COMMAND\" for help with a command"
  end

  def instances
    @state.instances
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
    puts command.run(self, *arguments)
  end

  def parse_args_with_schema(args, schema)
    schema.zip(args).map do |argument, string|
      argument.parse(self, string)
    end
  end
end
