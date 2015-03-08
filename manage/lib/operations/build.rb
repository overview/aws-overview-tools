require 'digest'
require 'fileutils'
require 'tempfile'

require_relative '../artifact'
require_relative '../log'
require_relative '../remote_builder'

module Operations
  # Derives an Artifact from a Source and version
  #
  # Usage
  # -----
  #
  #     source = ... a Source ...
  #     treeish = 'master' # or a sha1 or a tag
  #     build = Build.new(source, treeish)
  #     artifact = build.run
  #     artifact.sha        # 'a1b2c3d4e5f6....'
  #     artifact.key        # 'a1b2c3d4e4f6....zip'
  #     artifact.md5sum_key # 'a1b2c3d4e5f6....md5sum'
  #     artifact.valid?     # should be true
  #
  # When you run, Build does this:
  #
  # 1. Runs `git archive` to generate a snapshot
  # 2. Extracts the archive to a (temporary) build directory
  # 3. Runs `source.build_commands` in order as shell commands
  # 4. Copies _archive.zip_ (which build_commands must generate) to
  #    `artifact.key` on S3 (its permanent home).
  # 5. Generates an md5sum of _archive.zip_ and puts it in
  #    `artifact.md5sum_key` on S3.
  # 6. Deletes the build directory
  # 7. Deletes the git archive
  #
  # Remote builds
  # -------------
  #
  # If `source.build_remotely? == true`, then the `Build` operation will rely
  # on `RemoteBuilder` to spin up an Amazon EC2 instance to perform the build.
  # Details are in the `RemoteBuilder` class; we must initialize the `Build`
  # with a couple of options, though:
  #
  # * `connect_to_ec2`: a block that returns an `AWS::EC2` object.
  # * `remote_build_options`: a bunch of options.
  class Build
    attr_reader(:source, :treeish, :s3_bucket)

    def initialize(source, treeish, options = {})
      @source = source
      @treeish = treeish
      @options = options
      @s3_bucket = source.s3_bucket
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
        $log.info('build') { "Building in #{path}" }
        Dir.chdir(path) do
          system('tar', 'xzf', archive.path)

          yield
        end
      end

    ensure
      FileUtils.remove_entry(archive.path, true)
    end

    def run
      artifact = Artifact.new(@source, sha)

      if !artifact.valid?
        $log.info('build') { "Building" }
        if @source.build_remotely?
          build_on_ec2_instance(artifact)
        else
          build_on_this_machine(artifact)
        end
      end

      artifact
    end

    private

    def build_on_ec2_instance(artifact)
      $log.info('build') { "Building on a new EC2 instance" }

      ec2 = @options[:connect_to_ec2].call()

      archive = @source.archive(sha)

      remote_builder = RemoteBuilder.new(ec2, @options[:remote_build_config])

      Tempfile.open('artifact-zip') do |artifact_zip|
        md5sum = remote_builder.build(archive.path, @source.build_commands, artifact_zip.path)
        artifact_zip = artifact_zip.open # reopen
        s3_bucket.upload_file_to_key(artifact_zip, artifact.key)
        s3_bucket.upload_string_to_key(md5sum, artifact.md5sum_key)
      end
    ensure
      FileUtils.remove_entry(archive, true)
    end

    def build_on_this_machine(artifact)
      $log.info('build') { "Building locally" }
      in_build_directory do
        for command in commands
          $log.info('build') { "Running #{command}" }
          %x(#{command})
        end

        # Write zip
        $log.info('build') { "Copying archive.zip to s3" }
        File.open('archive.zip') do |f|
          s3_bucket.upload_file_to_key(f, artifact.key)
        end
        $log.info('build') { "Generating md5sum" }
        s3_bucket.upload_string_to_key(Digest::MD5.file('archive.zip').hexdigest, artifact.md5sum_key)
      end
    end
  end
end
