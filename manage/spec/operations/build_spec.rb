require 'base64'
require 'digest'
require 'shell'
require 'tempfile'

require 'source'
require 'operations/build'
require 'remote_builder'

RSpec.describe Operations::Build do
  # A tarball containing "foo/bar.txt" with contents "baz"
  #
  # This is mock source code, as produced from "git archive"
  TarballContents = Base64.decode64('''
    H4sIABAFaFMAA+3RPQrCQBCG4ak9xZ5A93/Os0HSSSCuIJ7ebCEEiwSERcT3aaaYgfngG6fpJJ3Z
    hWpq02my6/kizofgVGO2KtZZH4OY1DtYc7vWMhsj5VwuW3d7+x81Lv0PZT7We+32oxWcc9zoP771
    71L0Ymy3RCt/3v9QHodvZwAAAAAAAAAAAAAAAADwmScFkK8tACgAAA==
    ''')

  # A zipfile containing "foo.txt" with contents "bar"
  #
  # This is mock archive, as produced from the build.
  ZipContents = Base64.decode64('''
    UEsDBAoAAAAAADCOpUTps6IEBAAAAAQAAAAHABwAZm9vLnR4dFVUCQADawdoU2sHaFN1eAsAAQTo
    AwAABOgDAABiYXIKUEsBAh4DCgAAAAAAMI6lROmzogQEAAAABAAAAAcAGAAAAAAAAQAAALSBAAAA
    AGZvby50eHRVVAUAA2sHaFN1eAsAAQToAwAABOgDAABQSwUGAAAAAAEAAQBNAAAARQAAAAAA
    ''')

  before(:each) do
    @source_archive_file = Tempfile.new('overview-manage-operations-build-spec')
    @source_archive_file.write(TarballContents)
    @source_archive_file.close()

    @source = instance_double('Source',
      name: 'source-name',
      build_commands: [ "echo '#{Base64.strict_encode64(ZipContents)}' | base64 -d > archive.zip" ],
      build_remotely?: false,
      revparse: 'abcdef'
    )
    allow(@source).to receive(:archive) { |sha| double(sha: sha, path: @source_archive_file.path) }
  end

  after(:each) do
    @source_archive_file.close!
  end

  before(:each) do
    @build_dir = build_dir = Dir.mktmpdir

    # Can't put stub_const in an around(:each)...
    class MockSourceArtifact
      attr_accessor(:source, :sha)
      def initialize(source, sha, options = {})
        @source = source
        @sha = sha
        @options = options
      end

      def path; 'REPLACEME'; end
      def zip_path; path + "/foo.zip"; end
      def md5sum_path; path + "/md5sum"; end
      def valid?; false; end
    end

    allow_any_instance_of(MockSourceArtifact).to receive(:path).and_return(@build_dir)

    stub_const('SourceArtifact', MockSourceArtifact)
  end

  describe 'with a remote build' do
    before(:each) do
      @remote_builder = instance_double('RemoteBuilder')
      allow(@remote_builder).to receive(:build)
      allow(RemoteBuilder).to receive(:new).and_return(@remote_builder)
    end

    subject do
      @ec2 = double()
      connect_to_ec2 = lambda { @ec2 }
      @remote_build_config = double()
      allow(@source).to receive(:build_remotely?).and_return(true)
      Operations::Build.new(@source, 'master', connect_to_ec2: connect_to_ec2, remote_build_config: @remote_build_config)
    end

    it 'should not create a build directory' do
      expect(subject).not_to receive(:in_build_directory)
      subject.run
    end

    it 'should run through a remote builder with EC2 set' do
      expect(RemoteBuilder).to receive(:new) do |ec2, attrs|
        expect(ec2).to equal(@ec2)
        expect(attrs).to equal(@remote_build_config)
        @remote_builder
      end
      expect(@remote_builder).to receive(:build).with(@source_archive_file.path, @source.build_commands, "#{@build_dir}/foo.zip")
      subject.run
    end

    it 'should write the md5sum' do
      expect(@remote_builder).to receive(:build).and_return('abcdef123456')
      subject.run
      expect(open("#{@build_dir}/md5sum") { |f| f.read() }).to eq('abcdef123456')
    end

    it 'should not build when the build is already valid' do
      expect_any_instance_of(MockSourceArtifact).to receive(:valid?).and_return(true)
      expect(@remote_builder).not_to receive(:build)
      subject.run
    end
  end

  describe 'with local build' do
    subject { Operations::Build.new(@source, 'master') }

    after(:each) do
      FileUtils.remove_entry(@build_dir)
    end

    it 'should pick up commands from the Source' do
      expect(subject.commands).to equal(@source.build_commands)
    end

    it 'should revparse the treeish' do
      expect(@source).to receive(:revparse).with('master').and_return('abcdef123456')
      expect(subject.sha).to eq('abcdef123456')
    end

    it 'should build in a temporary directory' do
      dir1 = Dir.pwd
      dir2 = nil

      subject.in_build_directory do
        dir2 = Dir.pwd
      end

      expect(dir2).not_to eq(dir1)
      expect(dir2).to match(/overview-manage-build-source-name/)
      expect(Dir.pwd).to eq(dir1)
    end

    it 'should extract the source to the build directory' do
      subject.in_build_directory do
        contents = open('foo/bar.txt') { |f| f.read() }
        expect(contents.strip).to eq('baz')
      end
    end

    it 'should delete the temporary directory after build' do
      path = nil

      subject.in_build_directory do
        path = Dir.pwd
      end

      expect(File.exist?(path)).to eq(false)
    end

    it 'should run build_commands' do
      begin
        file = Tempfile.new('overview-manage-operations-build-spec')
        @source.build_commands << "echo 'foo' > #{file.path}"
        subject.run

        expect(file.read()).to eq("foo\n")
      ensure
        file.close!
      end
    end

    it 'should not build when the build is already valid' do
      begin
        file = Tempfile.new('overview-manage-operations-build-spec')
        @source.build_commands << "echo 'foo' > #{file.path}"
        expect_any_instance_of(MockSourceArtifact).to receive(:valid?).and_return(true)
        subject.run

        expect(file.read()).to eq("")
      ensure
        file.close!
      end
    end

    describe 'with the SourceArtifact .run returns' do
      it { expect(subject.run).to be_a(MockSourceArtifact) }
      it { expect(subject.run.sha).to eq('abcdef') }
      it { expect(subject.run.source).to eq('source-name') }

      it 'should put archive.zip in source_artifact' do
        zip = open(subject.run.zip_path, 'rb') { |f| f.read() }
        expect(zip).to eq(ZipContents)
      end

      it 'should add archive.md5sum in source_artifact' do
        md5sum = open(subject.run.md5sum_path, 'rb') { |f| f.read() }
        expect(md5sum).to eq(Digest::MD5.new.hexdigest(ZipContents))
      end
    end
  end
end
