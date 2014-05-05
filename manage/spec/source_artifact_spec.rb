require 'base64'
require 'fileutils'

require 'source_artifact'

RSpec.describe SourceArtifact do

  ZipContents = Base64.decode64('''
    UEsDBAoAAAAAAKRSpUTVotyLBgAAAAYAAAAHABwAZm9vLnR4dFVUCQADU55nU1OeZ1N1eAsAAQTo
    AwAABOgDAAAiYmFyIgpQSwECHgMKAAAAAACkUqVE1aLciwYAAAAGAAAABwAYAAAAAAABAAAAtIEA
    AAAAZm9vLnR4dFVUBQADU55nU3V4CwABBOgDAAAE6AMAAFBLBQYAAAAAAQABAE0AAABHAAAAAAA=
  ''')

  ZipMd5sum = 'fde3b19cdf36019e93c26444bc895b18'

  it 'should choose a good path' do
    class MockSource
      attr_reader(:name)

      def initialize(name)
        @name = name
      end
    end

    source = MockSource.new('source')
    artifact = SourceArtifact.new(source, 'abcdef')

    expect(artifact.path).to eq('/opt/overview/manage/source-artifacts/source/abcdef')
    expect(artifact.zip_path).to eq('/opt/overview/manage/source-artifacts/source/abcdef/archive.zip')
    expect(artifact.md5sum_path).to eq('/opt/overview/manage/source-artifacts/source/abcdef/archive.md5sum')
  end

  describe 'with the filesystem mocked' do
    around(:each) do |example|
      Dir.mktmpdir("overview-manage") do |dir|
        @root_path = dir
        @source = MockSource.new('a-source')
        @artifact = SourceArtifact.new(@source, 'abcdef', root: dir)
        FileUtils.mkdir_p("#{dir}/a-source/abcdef")
        example.run()
      end
    end

    it 'should not valid? if artifact.zip is missing' do
      open("#{@artifact.path}/archive.md5sum", 'wb') { |f| f.write(ZipMd5sum) }
      expect(@artifact.valid?).to be(false)
    end

    it 'should not valid? if artifact.md5sum is missing' do
      open("#{@artifact.path}/archive.zip", 'wb') { |f| f.write(ZipContents) }
      expect(@artifact.valid?).to be(false)
    end

    it 'should not valid? if artifact.md5sum does not match artifact.zip' do
      open("#{@artifact.path}/archive.zip", 'wb') { |f| f.write(ZipContents) }
      open("#{@artifact.path}/archive.md5sum", 'wb') { |f| f.write(ZipMd5sum.tr('f', 'a')) }
      expect(@artifact.valid?).to be(false)
    end

    it 'should valid? if artifact.md5sum matches artifact.zip' do
      open("#{@artifact.path}/archive.zip", 'wb') { |f| f.write(ZipContents) }
      open("#{@artifact.path}/archive.md5sum", 'wb') { |f| f.write(ZipMd5sum) }
      expect(@artifact.valid?).to be(true)
    end
  end
end
