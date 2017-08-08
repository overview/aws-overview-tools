require_relative 'operations/restart'
require_relative 'operations/start'
require_relative 'operations/stop'

# Runs publish/restart.
#
# overview-manage has a "pipeline" of commands which must be executed in order.
# Each step in the pipeline depends upon the previous step. Each step begins
# with a Source.
class PipelineCommandRunner
  def initialize(runner)
    @runner = runner
  end

  # Overwrites s3://[bucket]/[environment].zip
  #
  # Returns nil
  def publish(source, sha1, environment)
    source = @runner.sources[source]
    source.s3_bucket.cp("#{sha1}.zip", "#{environment}.zip")
    nil
  end

  # Does publish -> restart for the given machines.
  #
  # Returns nil
  def deploy(source, sha1, machine_spec)
    publish(source, sha1, machine_spec.split('/')[0])
    restart(machine_spec)
  end

  # Calls restart for the given machines.
  def restart(machine_spec)
    machines(machine_spec).each do |machine|
      Operations::Restart.new(machine).run
    end
  end

  # Calls start for the given machines.
  def start(machine_spec)
    machines(machine_spec).each do |machine|
      Operations::Start.new(machine).run
    end
  end

  # Calls stop for the given matches.
  def stop(machine_spec)
    machines(machine_spec).each do |machine|
      Operations::Stop.new(machine).run
    end
  end

  private

  def machines(machine_spec)
    machines = @runner.machines_with_spec(machine_spec)
    throw ArgumentError.new("There are no machines with specification '#{machine_spec}'") if machines.empty?
    machines
  end
end
