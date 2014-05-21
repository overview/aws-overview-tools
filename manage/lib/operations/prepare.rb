require 'erb'
require 'fileutils'

require_relative '../cleaner'
require_relative '../component_artifact'
require_relative '../log'
require_relative '../machine_shell'

module Operations
  # Derives a ComponentArtifact from a SourceArtifact and Component
  #
  # Usage:
  #
  #     source_artifact = ... a SourceArtifact ...
  #     component = ... a Component ...
  #     environment = 'production'
  #     prepare = Prepare.new(source_artifact, component, environment)
  #     component_artifact = prepare.run
  #     component_artifact.sha         # 'a1b2c3d4e5f6....'
  #     component_artifact.files       # Array of file paths
  #     component_artifact.md5sum_path # Manifest
  #     component_artifact.valid?      # should be true
  #
  # When you run, Prepare does this:
  #
  # 1. Extracts the SourceArtifact to a (temporary) build directory
  # 2. Runs `component.prepare_commands` in order as shell commands
  # 3. moves prepared `component` files (recursively) to
  #    `component_artifact.files_path`
  # 4. Generates an md5sum checksum file and puts it in
  #    `component_artifact.md5sum_path`
  # 5. Deletes the build directory
  # 6. Deletes old component artifacts
  #
  # Build environment
  # -----------------
  #
  # How should you author your build commands? Keep these tips in mind:
  #
  # * You are in a temporary directory.
  # * `./source` is the extracted source artifact. You are assured it is valid.
  # * Write output files to `./component`.
  # * You may use parameter substitution. For instance:
  #   `"cp -a source/<%= environment %>/<%= component.name[7..-1] %>/* component"`
  #   will look up `environment` and `component`. (These are the only exposed
  #   variables.)
  class Prepare
    attr_reader(:source_artifact, :component, :environment)

    def initialize(source_artifact, component, environment)
      @source_artifact = source_artifact
      @component = component
      @environment = environment
    end

    def commands
      @component.prepare_commands
    end

    def in_build_directory(&block)
      Dir.mktmpdir("overview-manage-prepare-#{@component.name}") do |path|
        $log.info('prepare') { "Preparing in #{path}" }
        Dir.chdir(path) do
          Dir.mkdir('source')
          Dir.chdir('source') do
            system('unzip', '-qq', @source_artifact.zip_path)
          end
          Dir.mkdir('component')

          yield
        end
      end
    end

    def run
      component_artifact = ComponentArtifact.new(@component.name, @source_artifact.sha, @environment)

      if !component_artifact.valid?
        $log.info('prepare') { "Creating empty destination directory #{component_artifact.path}" }
        if File.exist?(component_artifact.path)
          FileUtils.remove_entry(component_artifact.path)
        end
        FileUtils.mkdir_p(component_artifact.path)

        in_build_directory do
          for command in commands
            # Normally we'd create a custom binding, but why bother? This isn't
            # a security issue because we're the ones writing the YAML.
            real_command = ERB.new(command).result(binding)
            if !system(real_command)
              throw "Command failed: #{real_command}"
            end
          end

          $log.info('prepare') { "Copying files and md5sum to #{component_artifact.path}" }
          Dir.chdir('component') do
            md5sums = %x(find . -type f | cut -b 3- | xargs md5sum -b)
            open(component_artifact.md5sum_path, 'w') { |f| f.write(md5sums) }
          end
          FileUtils.mv('component', component_artifact.files_path)
        end
      end

      clean_old_component_artifacts

      component_artifact
    end

    private

    def clean_old_component_artifacts
      shell = MachineShell.new(nil)
      Cleaner.clean(:component_artifacts, shell)
    end
  end
end
