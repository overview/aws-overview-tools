require 'digest'
require 'fileutils'

module Operations
  # Derives a SourceArtifact from a Source and version
  #
  # Usage:
  #
  #     source = ... a Source ...
  #     treeish = 'origin/master' # or a sha1 or a tag
  #     build = Build.new(source, treeish)
  #     source_artifact = build.run
  #     source_artifact.sha         # 'a1b2c3d4e5f6....'
  #     source_artifact.zip_file    # '/path/to/archive.zip'
  #     source_artifact.md5sum_file # '/path/to/md5sum'
  #     source_artifact.valid?      # should be true
  #
  # When you run, Build does this:
  #
  # 1. Runs `git archive` to generate a snapshot
  # 2. Extracts the archive to a (temporary) build directory
  # 3. Runs `source.build_commands` in order as shell commands
  # 4. Copies _archive.zip_ (which build_commands must generate) to
  #    `source_artifact.zip_path` (its permanent home).
  # 5. Generates an md5sum of _archive.zip_ and puts it in
  #    `source_artifact.md5sum_path`
  # 6. Deletes the build directory
  # 7. Deletes the git archive
  class Build
    def initialize(source, treeish)
      @source = source
      @treeish = treeish
    end

    def commands
      @source.build_commands
    end

    def sha
      @sha ||= @source.revparse(@treeish)
    end

    def in_build_directory(&block)
      archive = @source.archive(sha)

      Dir.mktmpdir("overview-manage-build-#{@source.name}") do |path|
        Dir.chdir(path) do
          system('tar', 'xzf', archive.file.path)

          yield
        end
      end

    ensure
      archive.file.unlink
    end

    def run
      source_artifact = SourceArtifact.new(@source.name, sha)

      if !source_artifact.valid?
        FileUtils.remove_entry(source_artifact.path)
        FileUtils.mkdir_p(source_artifact.path)

        in_build_directory do
          for command in commands
            %x(#{command})
          end

          # Write zip
          FileUtils.cp('archive.zip', source_artifact.zip_path)

          # Write md5sum
          md5sum = Digest::MD5.file('archive.zip').hexdigest
          open(source_artifact.md5sum_path, 'w') do |f|
            f.write(md5sum)
          end
        end
      end

      source_artifact
    end
  end
end