require 'git'

# A wrapper around a bare Git repo
class Source
  # An archive file of a source at a version
  class SourceArchive
    attr_reader(:sha, :file)

    def initialize(sha, file)
      @sha = sha
      @file = file
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
    repo.fetch
  end

  def archive(treeish)
    object = repo.object(treeish)
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
      Git::Base.clone(url, name, bare: true, path: bare_git_repo_path)
    end
  end

  def bare_git_repo_path
    "/opt/overview/manage/sources/#{name}.git"
  end
end
