require 'aws-sdk'
require 'stringio'

require_relative 'log'

class S3Bucket
  attr_reader(:bucket)

  def initialize(bucket)
    @bucket = bucket
  end

  def s3
    @s3 ||= Aws::S3::Client.new
  end

  def exists?(key)
    debug("exists?(#{key})")
    s3.head_object(bucket: bucket, key: key)
    true
  rescue Aws::S3::Errors::NoSuchKey
    false
  rescue Aws::S3::Errors::NotFound
    false
  end

  def cp(source_key, destination_key)
    info("cp(#{source_key}, #{destination_key})")
    s3.copy_object(
      copy_source: "#{bucket}/#{source_key}",
      bucket: bucket,
      key: destination_key
    )
  end

  private

  def info(message)
    $log.info('s3-bucket') { "[bucket:#{bucket}] #{message}" }
  end

  def debug(message)
    $log.debug('s3-bucket') { "[bucket:#{bucket}] #{message}" }
  end
end
