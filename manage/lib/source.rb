require 'git'

require_relative 'log'

# A wrapper around a bare Git repo
class Source
  # An archive file of a source at a version
  class SourceArchive
    attr_reader(:sha, :path)

    def initialize(sha, path)
      @sha = sha
      @path = path
    end
  end

  attr_reader(:name, :url, :build_commands)

  def initialize(hash_or_instance)
    if hash_or_instance.is_a?(Hash)
      @name = hash_or_instance['name'] || hash_or_instance[:name]
      @url = hash_or_instance['url'] || hash_or_instance[:url]
      @build_commands = hash_or_instance['build_commands'] || hash_or_instance[:build_commands] || []
      @build_remotely = hash_or_instance['build_remotely'] || hash_or_instance[:build_remotely] || false
    else
      @name = hash_or_instance.name
      @url = hash_or_instance.url
      @build_commands = hash_or_instance.build_commands
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
    repo.revparse("#{treeish}^{commit}")
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
