require 'erb'
require 'fileutils'

require 'component_artifact'

module Operations
  # Derives a ComponentArtifact from a SourceArtifact and Component
  #
  # Usage:
  #
  #     source_artifact = ... a SourceArtifact ...
  #     component = ... a Component ...
  #     prepare = Prepare.new(source_artifact, component)
  #     component_artifact = prepare.run
  #     component_artifact.sha         # 'a1b2c3d4e5f6....'
  #     component_artifact.files       # Array of file paths
  #     component_artifact.md5sum_path # Manifest
  #     component_artifact.valid?      # should be true
  #
  # When you run, Build does this:
  #
  # 1. Extracts the SourceArtifact to a (temporary) build directory
  # 2. Runs `component.prepare_commands` in order as shell commands
  # 3. moves prepared `component` files (recursively) to
  #    `component_artifact.files_path`
  # 4. Generates an md5sum checksum file and puts it in
  #    `component_artifact.md5sum_path`
  # 5. Deletes the build directory
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

          Dir.chdir('component') do
            md5sums = %x(find . -type f | cut -b 3- | xargs md5sum -b)
            open(component_artifact.md5sum_path, 'w') { |f| f.write(md5sums) }
          end
          FileUtils.mv('component', component_artifact.files_path)
        end
      end

      component_artifact
    end
  end
end
