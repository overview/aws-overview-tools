require 'digest'
require 'fileutils'

module Operations
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
      source_artifact = SourceArtifact.new(@source, sha)

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
