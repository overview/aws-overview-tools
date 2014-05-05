# A compiled source-code artifact.
#
# A SourceArtifact must persist from build to build. That means all metadata
# can be derived just by looking at the filesystem.
#
# A SourceArtifact has a "source" and a "sha" (version). These point to a path
# on the filesystem:
# `path = "/opt/overview/manage/artifacts/sources/#{source.name}/#{sha}"`.
#
# * #{path}/artifact.zip: the built Source.
# * #{path}/artifact.md5sum: an md5sum.
#
# When building a SourceArtifact, don't assume it's there already. Consider
# it a cached value: if it's there you can use it; if it isn't there, you need
# to build it.
#
# 1. `source_artifact = SourceArtifact.new(source, sha)`
# 2. `source_artifact.verify`
# 3. If `.verify` is false, rebuild: rm_r `source_artifact.path`, recreate
#    it and write new `artifact.zip` and `artifact.md5sum` to
#    `source_artifact.zip_path` and `source_artifact.md5sum_path`
class SourceArtifact
  attr_reader(:source, :sha)

  def initialize(source, sha, options = {})
    @source = source
    @sha = sha
    @options = options
  end

  def path
    root = @options[:root] || "/opt/overview/manage/source-artifacts"
    "#{root}/#{source.name}/#{sha}"
  end

  def zip_path
    "#{path}/archive.zip"
  end

  def md5sum_path
    "#{path}/archive.md5sum"
  end

  def valid?
    from_file = md5sum_from_file
    from_zip = md5sum_from_zip

    from_file && from_zip && from_file == from_zip || false
  end

  private

  def md5sum_from_file
    open(md5sum_path, 'rb') { |f| f.read().strip() }
  rescue
    nil
  end

  def md5sum_from_zip
    Digest::MD5.file(zip_path).hexdigest
  rescue
    nil
  end
end
