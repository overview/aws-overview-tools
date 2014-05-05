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

  attr_reader(:name, :url)

  def initialize(hash_or_instance)
    if hash_or_instance.is_a?(Hash)
      @name = hash_or_instance['name'] || hash_or_instance[:name]
      @url = hash_or_instance['url'] || hash_or_instance[:url]
    else
      @name = hash_or_instance.name
      @url = hash_or_instance.url
    end
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
