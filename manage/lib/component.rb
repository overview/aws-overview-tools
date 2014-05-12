class Component
  attr_reader(:name, :source, :prepare_commands, :deploy_commands)

  def initialize(hash)
    @name = hash[:name] || hash['name']
    @source = hash[:source] || hash['source']
    @prepare_commands = hash[:prepare_commands] || hash['prepare_commands'] || []
    @deploy_commands = hash[:deploy_commands] || hash['deploy_commands'] || []
  end

  def self.from_yaml(name, yaml)
    hash = { name: name }.update(yaml)
    Component.new(hash)
  end

  def to_s; name end

  def install_path
    "/opt/overview/#{name}"
  end

  def prepare_path(sha, env)
    "/opt/overview/manage/component-artifacts/#{name}/#{sha}/#{env}"
  end
end
