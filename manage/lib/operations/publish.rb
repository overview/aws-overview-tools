require_relative '../log'

module Operations
  # Makes an Artifact the official one for the given environment.
  #
  # In particular: copies #{sha}.zip and #{sha}.md5sum to #{env}.zip and
  # #{env}.md5sum.
  #
  # Usage:
  #
  #     artifact = ... an Artifact...
  #     environment = 'staging'
  #     Publish.new(artifact, environment).run
  class Publish
    attr_reader(:artifact, :environment)

    def initialize(artifact, environment, options = {})
      @artifact = artifact
      @environment = environment
      @options = options
    end

    def run
      $log.info('publish') { "Publishing #{artifact.sha} in #{environment}" }
      artifact.s3_bucket.cp(artifact.key, "#{environment}.zip")
      artifact.s3_bucket.cp(artifact.md5sum_key, "#{environment}.md5sum")
    end
  end
end
