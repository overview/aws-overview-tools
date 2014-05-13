require_relative 'operations/build'
require_relative 'operations/prepare'
require_relative 'operations/publish'
require_relative 'operations/install'
require_relative 'operations/deploy'

require_relative 'source_artifact'

# Runs build/prepare/publish/install/deploy with string arguments.
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
# * The "prepare" method takes a String source and a String version, not a
#   SourceArtifact.
# * The "prepare" command calls the "build" command automatically.
class PipelineCommandRunner
  def initialize(runner)
    @runner = runner
  end

  # Builds the given source name at the given version.
  #
  # This is the fastest way to go from Strings to a SourceArtifact.
  #
  # We assume the source name refers to an actual source. We don't know if the
  # version refers to an actual version; we trust Operations::Build to raise an
  # exception if it doesn't.
  #
  # If there is already a SourceArtifact for this name and sha (we git fetch
  # and revparse the version), we skip Building.
  #
  # Returns a SourceArtifact that we assume is valid.
  def build(source_name, version)
    source = @runner.sources[source_name]

    source.fetch
    sha = source.revparse(version)

    try_artifact = SourceArtifact.new(source_name, sha)
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

  # Prepares the given source at the given version for the given environment.
  #
  # We assume the source name refers to an actual source. We don't know if the
  # version refers to an actual version; we trust Operations::Build to raise an
  # exception if it doesn't.
  #
  # Unlike build(), we _always_ do Operations::Prepare::run() on _every_
  # Component for the source. The rationale: for ComponentArtifacts that
  # already exist, the build amounts to a no-op.
  #
  # Returns an Array of ComponentArtifacts that we assume are valid.
  def prepare(source_name, version, environment)
    source_artifact = build(source_name, version)

    components = @runner.components_with_source(source_name)

    components.map do |component|
      Operations::Prepare.new(source_artifact, component, environment).run
    end
  end

  # Publishes components from the given source at the given version to the
  # given machines.
  #
  # This uses prepare() to find all ComponentArtifacts for the given source
  # at the given version. For each artifact, it finds all relevant Machines.
  # For each permutation, it calls
  # Operations::Publish(component_artifact, machine).
  #
  # We assume all machines share the same environment ('production' or
  # 'staging').
  #
  # Returns an Array of [component_artifact, machine ] pairs.
  def publish(source_name, version, machine_spec)
    machines = @runner.machines_with_spec(machine_spec)

    throw ArgumentError.new("There are no machines with specification '#{machine_spec}'") if machines.empty?

    environment = machines.first.environment

    prepare(source_name, version, environment)
      .product(machines)
      .select{ |ca, m| m.components.include?(ca.component) }
      .map do |ca, m|
        Operations::Publish.new(ca, m).run
        [ ca, m ]
      end
  end

  # Installs published components on the given machines.
  #
  # This uses publish() to fetch pairs of ComponentArtifacts and Machines.
  # Then it runs Operations::Install with each pair.
  #
  # Returns an Array of [ component_artifact, machine ] pairs.
  def install(source_name, version, machine_spec)
    publish(source_name, version, machine_spec)
      .map do |component_artifact, machine|
        Operations::Install.new(component_artifact, machine).run

        [ component_artifact, machine ]
      end
  end

  # Deploys installed components on the given machines.
  #
  # This uses install() to fetch pairs of ComponentArtifacts and Machines.
  # Then it runs Operations::Deploy with the corresponding (Component, Machine)
  # pairs.
  #
  # Returns an Array of [ component_artifact, machine ] pairs.
  def deploy(source_name, version, machine_spec)
    ret = install(source_name, version, machine_spec)

    ret.each do |component_artifact, machine|
      component = @runner.components[component_artifact.component]
      Operations::Deploy.new(component, machine).run
    end

    ret
  end
end
