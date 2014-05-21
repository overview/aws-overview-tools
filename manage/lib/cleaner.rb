require_relative 'log'

module Cleaner
  # Deletes old versions of artifacts from the given computer.
  #
  # Usage:
  #
  #   shell = MachineShell.new(nil) # local computer
  #   Cleaner.clean(:component_artifacts, shell, keep: 5)
  #
  # This method will list all the artifacts of the given type
  # (:source_artifacts or :component_artifacts) with the given shell, and it
  # will delete the oldest ones. It will not delete an artifact that is
  # currently installed.
  #
  # Options:
  #
  # * keep: (default 10) number of versions to keep. Keeping lots of artifacts
  #         won't make this method appreciably slower, but it can eat up disk
  #         space.
  def self.clean(things, shell, options = {})
    options = { keep: 10 }.update(options)

    # shell.source_artifacts_with_timestamps -> Struct(source_artifact: x, timestamp: y)
    # source_artifact -> group by source
    # component_artifact -> group by [component,environment]
    things_getter = "#{things}_with_timestamps".to_sym
    thing_getter = things.to_s.chomp('s').to_sym
    group_by = if things == :source_artifacts
      lambda { |artifact| artifact.source }
    else
      lambda { |artifact| "#{artifact.component}/#{artifact.environment}" }
    end

    $log.info('cleaner') { "Cleaning old #{things}..." }
    install_paths = {}

    xs = shell.send(things_getter)
    groups = xs.sort { |a, b| b.timestamp <=> a.timestamp }
      .map { |x| x.send(thing_getter) }
      .group_by(&group_by)
      .values

    for group in groups
      while group.length > options[:keep]
        artifact = group.pop

        skip = false

        if artifact.respond_to?(:install_path)
          install_path = install_paths[artifact.install_path] ||= shell.readlink(artifact.install_path)
          if install_path == artifact.path
            skip = true # This is the installed one; we should not remove it.
          end
        end

        shell.rm_rf(artifact.path) if !skip
      end
    end
  end
end
