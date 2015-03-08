require 'aws-sdk'
require 'stringio'

class S3Bucket
  attr_reader(:bucket)

  def initialize(bucket)
    @bucket = bucket
  end

  def s3
    @s3 ||= Aws::S3::Client.new
  end

  def exists?(key)
    s3.head_object(
      bucket: bucket,
      key: key
    )
    true
  rescue Aws::S3::Errors::NoSuchKey
    false
  rescue Aws::S3::Errors::NotFound
    false
  end

  def cat(key)
    StringIO.open("") do |io|
      s3.get_object(
        bucket: @bucket,
        key: key,
        response_target: file
      )
      io.close_write
      io.string
    end
  end

  def cp(source_key, destination_key)
    s3.copy_object(
      copy_source: "#{bucket}/#{source_key}",
      bucket: bucket,
      key: destination_key
    )
  end

  def upload_string_to_key(string, key)
    s3.put_object(
      bucket: bucket,
      key: key,
      body: string
    )
  end

  def upload_file_to_key(file, key)
    s3.put_object(
      bucket: bucket,
      key: key,
      body: file
    )
  end

  def download_key_to_file(key, file)
    s3.get_object(
      bucket: bucket,
      key: key,
      response_target: file
    )
  end
end
