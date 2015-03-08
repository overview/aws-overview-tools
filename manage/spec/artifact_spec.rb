require 'base64'
require 'fileutils'

require 'artifact'

RSpec.describe Artifact do
  module ArtifactConstants
    ZipContents = Base64.decode64('''
      UEsDBAoAAAAAAKRSpUTVotyLBgAAAAYAAAAHABwAZm9vLnR4dFVUCQADU55nU1OeZ1N1eAsAAQTo
      AwAABOgDAAAiYmFyIgpQSwECHgMKAAAAAACkUqVE1aLciwYAAAAGAAAABwAYAAAAAAABAAAAtIEA
      AAAAZm9vLnR4dFVUBQADU55nU3V4CwABBOgDAAAE6AMAAFBLBQYAAAAAAQABAE0AAABHAAAAAAA=
    ''')

    ZipMd5sum = 'fde3b19cdf36019e93c26444bc895b18'
  end

  before(:each) do
    @source = double(name: 'name', s3_bucket: 's3-bucket')
    @sha = 'abcdef'
    @artifact = Artifact.new(@source, @sha)
  end

  it 'should have a key' do
    expect(@artifact.key).to eq('abcdef.zip')
  end

  it 'should have an md5sum key' do
    expect(@artifact.md5sum_key).to eq('abcdef.md5sum')
  end
end
