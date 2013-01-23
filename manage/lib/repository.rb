require 'fileutils'

require 'grit'
require 'net/scp'

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

class Repository
  attr_reader(:managed_code_path, :name, :options, :repo)

  def initialize(config, name, options)
    @config = config
    @name = name
    @options = options

    if !File.exist?("#{repo_path}/.git")
      FileUtils.mkdir_p(repo_path)
      Grit::Git.new(repo_path).clone({ :raise => true, :timeout => 300 }, options['url'], repo_path)
    end

    @repo = Grit::Repo.new(repo_path)
  end

  def managed_code_path
    @managed_code_path ||= @config['managed_code_path']
  end

  def repo_path
    "#{path}/repo"
  end

  def current_commit
    head = Grit::Head.current(repo)
    commit = head.commit
    commit.id
  end

  def export_path
    "#{path}/#{current_commit}"
  end

  def path
    "#{managed_code_path}/#{name}"
  end

  def fetch
    puts "Fetching #{name} from git server..."
    repo.git.fetch(:timeout => 60)
  end

  def checkout(treeish)
    puts "Resetting to #{treeish} branch"
    repo.git.reset({}, '--hard', "origin/#{treeish}")
  end

  def build
    command = options['build_command']
    env = options['build_env'] || {}
    puts "Running #{command}..."
    pid = spawn(env, command, :chdir => repo_path)
    raise RuntimeError.new("Build failed") if Process::wait2(pid)[1].exitstatus != 0

    out_path = export_path # cache

    FileUtils::rm_r(out_path) if File.exist?(out_path)
    FileUtils::mkdir_p(out_path)
    command = options['export_command'].gsub('#{DESTINATION_PATH}', out_path)
    puts "Running #{command}..."
    pid = spawn(command, :chdir => repo_path)
    raise RuntimeError.new("Export failed") if Process::wait2(pid)[1].exitstatus != 0
  end

  def copy(env, instances)
    commit_path = export_path

    options['copy'].each do |type, glob|
      ip_addresses = instances.with_type(type).map(&:ip_address)
      glob = glob.gsub('#{ENV}', env)
      glob = glob.gsub('#{TYPE}', type)
      ip_addresses.each do |ip_address|
        puts "Connecting to #{env}.#{type} #{ip_address}"
        Net::SSH.start(ip_address, 'ubuntu') do |session|
          runner = SshRunner.new(session)

          puts "Ensuring #{path} exists"
          runner.exec("sudo mkdir -p /opt/overview")
          runner.exec("sudo chown ubuntu:ubuntu /opt/overview")
          runner.exec("mkdir -p #{path} /opt/overview/config")
          runner.exec("rm -rf #{commit_path}-t")

          puts "Uploading #{commit_path}/#{glob}"
          session.scp.upload!("#{commit_path}/#{glob}", "#{commit_path}-t", :recursive => true) do |ch, name, sent, total|
            puts "  uploaded #{name}" if sent == total
          end

          runner.exec("rm -rf #{commit_path} && mv #{commit_path}-t #{commit_path} && rm -f #{path}/current && ln -sf #{commit_path} #{path}/current")
        end
      end
    end
  end

  def install(instances)
    if name == 'config'
      instances.map { |i| install_config(i) }
    end
  end

  def restart(instances)
    start_script = "/opt/overview/managed-code/config/current/scripts/start.sh"

    instances.each do |instance|
      puts "Restarting #{instance.ip_address} (running #{start_script})"
      Net::SSH.start(instance.ip_address, 'ubuntu') do |session|
        runner = SshRunner.new(session)
        runner.exec("sudo initctl reload-configuration")
        runner.exec("sh #{start_script}")
      end
    end
  end

  protected

  def install_config(instance)
    ip_address = instance.ip_address
    puts "Linking config files on #{ip_address} to / (root) -- can't be undone..."
    Net::SSH.start(ip_address, 'ubuntu') do |session|
      runner = SshRunner.new(session)
      runner.exec("(cd #{path}/current/root && sudo find * -type f -exec ln -Pfv {} /{} \\;)")
    end
  end
end
