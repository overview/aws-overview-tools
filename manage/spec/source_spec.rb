require 'source'
require 'yaml'

module MockGit
  class Base
    def self.bare(path, opts = {})
      self.new
    end

    def self.clone(repository, name, opts = {})
      self.new
    end

    def fetch
    end
  end
end

RSpec.describe 'Source' do
  before(:each) do
    @subject = Source.new(name: 'source', url: 'https://github.com/example/example-source.git')
    stub_const('Git', MockGit, transfer_nested_contents: true)
  end

  it 'should serialize' do
    expect(@subject.to_hash['name']).to eq(@subject.name)
    expect(@subject.to_hash['url']).to eq(@subject.url)
  end

  it 'should deserialize' do
    source2 = Source.new(@subject)
    expect(source2.to_hash).to eq(@subject.to_hash)
  end

  it 'should create the repo when the repo does not exist' do
    module MockFile
      def self.exist?(path)
        false
      end
    end

    module MockFileUtils
      def self.mkdir_p(path)
        [ path ]
      end
    end

    stub_const('File', MockFile)
    stub_const('FileUtils', MockFileUtils)

    path = "/opt/overview/manage/sources/#{@subject.name}.git"
    expect(MockFile).to receive(:exist?).with(path).and_return(false)
    expect(MockFileUtils).to receive(:mkdir_p).with(path).and_return([])
    expect(MockGit::Base).to receive(:clone).with(@subject.url, @subject.name, bare: true, path: path).and_return(repository: path)
    @subject.fetch
  end

  it 'should default to empty build_commands' do
    expect(@subject.build_commands).to eq([])
  end

  it 'should default to false build_remotely?' do
    expect(@subject.build_remotely?).to eq(false)
  end

  it 'should initialize from YAML' do
    yaml = YAML.load("""---
      overview-server:
        url: https://github.com/overview/overview-server.git
        build_remotely: true
        build_commands:
          - ./build archive.zip
      """)
    source = Source.from_yaml('key', yaml['overview-server'])
    expect(source.name).to eq('key')
    expect(source.url).to eq('https://github.com/overview/overview-server.git')
    expect(source.build_commands).to eq([ './build archive.zip' ])
    expect(source.build_remotely?).to eq(true)
  end

  it 'should use the repo when it already exists' do
    module MockFile
      def self.exist?(path)
        true
      end
    end

    path = "/opt/overview/manage/sources/#{@subject.name}.git"
    stub_const('File', MockFile)

    expect(MockFile).to receive(:exist?).with(path).and_return(true)
    expect(MockGit::Base).to receive(:bare).with(path).and_return(MockGit::Base.new)
    @subject.fetch
  end

  describe 'with a repo' do
    before(:each) do
      @repo = Git::Base.new
      allow(@subject).to receive(:repo).and_return @repo
    end

    it 'should fetch' do
      expect(@repo).to receive(:fetch)
      @subject.fetch
    end

    it 'should find a sha' do
      expect(@repo).to receive(:revparse).and_return 'abcdef123456'
      sha = @subject.revparse('origin/master')
      expect(sha).to eq('abcdef123456')
    end

    it 'should give an archive a version' do
      class MockObject
      end
      mock_object = MockObject.new
      mock_file = Object.new

      expect(@repo).to receive(:object).with('origin/master').and_return(mock_object)
      allow(mock_object).to receive(:sha).and_return('abcdef')
      expect(mock_object).to receive(:archive).with(nil, format: 'tgz').and_return(mock_file)

      archive = @subject.archive('origin/master')
      expect(archive.sha).to eq('abcdef')
      expect(archive.file).to equal(mock_file)
    end
  end
end
