require 'digest'
require 'tempfile'

require_relative 'log'

# A compiled source-code artifact.
#
# An Artifact must persist from build to build. That means all metadata
# can be derived just by looking at S3.
#
# An Artifact has a "source" and a "sha" (version). These point to keys on S3:
#
# * #{s3-bucket}/#{sha}.zip: the built Source.
# * #{s3-bucket}/#{sha}.md5sum: an md5sum.
class Artifact
  attr_reader(:source, :sha, :s3_bucket)

  def initialize(source, sha)
    @source = source
    @sha = sha
    @s3_bucket = source.s3_bucket
  end

  def to_s; "Artifact(#{source.name}-#{sha})" end

  def key; "#{sha}.zip"; end

  def md5sum_key; "#{sha}.md5sum"; end

  def valid?
    $log.info('artifact') { "Validating #{to_s}" }

    from_file = md5sum_from_file
    from_zip = md5sum_from_zip

    from_file && from_zip && from_file == from_zip || false
  end

  private

  def md5sum_from_file
    if s3_bucket.exists?(md5sum_key)
      s3_bucket.cat(md5sum_key)
    else
      nil
    end
  end

  def md5sum_from_zip
    if s3_bucket.exists?(key)
      Template.open('artifact') do |f|
        download_key_to_file(key, f)
        f.close_write
        Digest::MD5.file(f.path).hexdigest
      end
    else
      nil
    end
  end

  def s3
    @s3 ||= Aws::S3::Client.new
  end

  def s3_object_exists?(key)
    s3.head_object(
      bucket: @options[:artifact_bucket],
      key: key
    )
    true
  rescue Aws::Errors::NoSuchKey => e
    false
  end
end
