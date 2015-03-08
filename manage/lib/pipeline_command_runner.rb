require_relative 'operations/build'
require_relative 'operations/publish'
require_relative 'operations/restart'
require_relative 'operations/start'
require_relative 'operations/stop'

require_relative 'artifact'

# Runs build/publish/restart with string arguments.
#
# overview-manage has a "pipeline" of commands which must be executed in order.
# Each step in the pipeline depends upon the previous step. Each step begins
# with a Source; each ends on either Machines or Artifacts.
#
# From the user's point of view, overview-manage persists its state between
# calls. That means the user will be specifying simple String arguments, and
# overview-manage needs to flesh out the Operations, Stores and models, and
# figure out what's already done and what's still necessary. That's where this
# object comes in.
#
# PipelineCommandRunner creates and runs Commands and their dependencies based
# only on Strings. For instance:
#
# * The "build" method just takes a String source and a String version, not
#   objects.
# * The "build" method is a no-op if there is already an Artifact for the
#   given source and version.
# * The "publish" method takes a String source and a String version, not an
#   Artifact.
# * The "publish" command calls the "build" command automatically.
class PipelineCommandRunner
  def initialize(runner)
    @runner = runner
  end

  # Builds the given source name at the given version.
  #
  # We assume the source name refers to an actual source. We don't know if the
  # version refers to an actual version; we trust Operations::Build to raise an
  # exception if it doesn't.
  #
  # If there is already an Artifact for this name and sha (we git fetch and
  # revparse the version), we skip Building.
  #
  # Returns a valid Artifact.
  def build(source_name, version)
    source = @runner.sources[source_name]

    source.fetch
    sha = source.revparse(version)

    try_artifact = Artifact.new(source, sha)
    if try_artifact.valid?
      try_artifact
    else
      Operations::Build.new(
        source,
        sha,
        connect_to_ec2: @runner.method(:connect_to_ec2),
        remote_build_config: @runner.remote_build_config
      ).run
    end
  end

  # Publishes an artifact as the official one for the given machines.
  #
  # We assume all machines share the same environment ('production' or
  # 'staging'). This lets you type this command:
  #
  # overview-manage publish overview-server@master production
  #
  # Returns nil
  def publish(source_name, version, environment)
    artifact = build(source_name, version)
    Operations::Publish.new(artifact, environment).run
  end

  # Does build -> publish -> restart for the given machines.
  #
  # Returns nil
  def deploy(source_name, version, machine_spec)
    publish(source_name, version, machine_spec.split('/')[0])
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
