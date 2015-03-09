class MachineType
  attr_reader(:name, :start_commands, :stop_commands, :restart_commands)

  def initialize(name, start_commands, stop_commands, restart_commands)
    @name = name
    @start_commands = start_commands
    @stop_commands = stop_commands
    @restart_commands = restart_commands
  end

  def self.from_yaml(name, yaml)
    MachineType.new(
      name,
      yaml['start_commands'] || [],
      yaml['stop_commands'] || [],
      yaml['restart_commands'] || []
    )
  end
end
