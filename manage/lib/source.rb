require 'shellwords'

require_relative 'log'
require_relative 's3_bucket'

# A wrapper around a bare Git repo
class Source
  attr_reader(:name, :url, :s3_bucket)

  def initialize(hash_or_instance)
    if hash_or_instance.is_a?(Hash)
      @name = hash_or_instance['name'] || hash_or_instance[:name]
      @url = hash_or_instance['url'] || hash_or_instance[:url]
      @s3_bucket = S3Bucket.new(hash_or_instance['artifact_bucket'] || hash_or_instance[:artifact_bucket] || 'no-bucket')
    else
      @name = hash_or_instance.name
      @url = hash_or_instance.url
      @s3_bucket = hash_or_instance.s3_bucket
    end
  end

  def self.from_yaml(name, yaml)
    hash = { name: name }.update(yaml)
    Source.new(hash)
  end

  def to_hash
    {
      'name' => name,
      'url' => url
    }
  end
end
