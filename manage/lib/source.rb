require 'git'

require_relative 'log'
require_relative 's3_bucket'

# A wrapper around a bare Git repo
class Source
  # An archive file of a source at a version.
  #
  # The file will be deleted when it is finalized or when `unlink` is called.
  class SourceArchive
    attr_reader(:sha, :path)

    def initialize(sha, path)
      @sha = sha
      @path = path

      ObjectSpace.define_finalizer(self, Remover.new(path))
    end

    def unlink
      ObjectSpace.undefine_finalizer(self)
      if !@data[1]
        File.unlink(@data[0])
        @data[1] = true
      end
    end

    private

    class Remover
      def initialize(path)
        @path = path
      end

      def call(*args)
        begin
          File.unlink(@path)
        rescue Errno::ENOENT
        end
      end
    end
  end

  attr_reader(:name, :url, :build_commands, :s3_bucket)

  def initialize(hash_or_instance)
    if hash_or_instance.is_a?(Hash)
      @name = hash_or_instance['name'] || hash_or_instance[:name]
      @url = hash_or_instance['url'] || hash_or_instance[:url]
      @build_commands = hash_or_instance['build_commands'] || hash_or_instance[:build_commands] || []
      @build_remotely = hash_or_instance['build_remotely'] || hash_or_instance[:build_remotely] || false
      @s3_bucket = S3Bucket.new(hash_or_instance['s3_bucket'] || hash_or_instance[:s3_bucket] || 'no-bucket')
    else
      @name = hash_or_instance.name
      @url = hash_or_instance.url
      @build_commands = hash_or_instance.build_commands
      @s3_bucket = hash_or_instance.s3_bucket
    end
  end

  def self.from_yaml(name, yaml)
    hash = { name: name }.update(yaml)
    Source.new(hash)
  end

  def build_remotely?
    @build_remotely
  end

  def to_hash
    {
      'name' => name,
      'url' => url
    }
  end

  def fetch
    $log.info('source') { "Fetching #{bare_git_repo_path}" }
    repo.fetch
  end

  def revparse(treeish)
    ret = if treeish =~ /\A[a-zA-Z0-9]{40}\Z/
      # https://github.com/schacon/ruby-git/issues/155
      treeish
    else
      repo.revparse("#{treeish}^{commit}")
    end
    $log.info('source') { "Revparse of #{treeish}: #{ret}" }
    ret
  end

  # Returns a Tempfile which is a tarball git repo's files in the directory
  # "checkout/"
  def archive(sha)
    path = repo.object(sha).archive(nil, format: 'tgz')
    SourceArchive.new(sha, path)
  end

  private

  def repo
    if !@repo
      ensure_repo_exists()
      @repo = Git::Base.bare(bare_git_repo_path)
    end

    @repo
  end

  def ensure_repo_exists
    if !File.exist?(bare_git_repo_path)
      FileUtils.mkdir_p(bare_git_repo_path)
      $log.info('source') { "Cloning #{url} to #{bare_git_repo_path}..." }
      repo = Git::Base.clone(url, repo_name, bare: true, path: bare_git_repos_path)
      repo.config('remote.origin.fetch', '+refs/*:refs/*')
      repo.config('remote.origin.mirror', true)
    end
  end

  def bare_git_repos_path
    "/opt/overview/manage/sources"
  end

  def repo_name
    "#{name}.git"
  end

  def bare_git_repo_path
    "#{bare_git_repos_path}/#{repo_name}"
  end
end
