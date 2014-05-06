require 'operations/prepare'

require 'base64'
require 'fileutils'
require 'ostruct'

RSpec.describe Operations::Prepare do
  module OperationsPrepareConstants
    # Zip with one file, "foo/bar.txt", contents "baz"
    ZipContents = Base64.decode64('
      UEsDBAoAAAAAANlspkQAAAAAAAAAAAAAAAAEABwAZm9vL1VUCQADKh5pUyIeaVN1eAsAAQToAwAA
      BOgDAABQSwMECgAAAAAA2WymROE5e8wEAAAABAAAAAsAHABmb28vYmFyLnR4dFVUCQADKh5pUyoe
      aVN1eAsAAQToAwAABOgDAABiYXoKUEsBAh4DCgAAAAAA2WymRAAAAAAAAAAAAAAAAAQAGAAAAAAA
      AAAQAP1BAAAAAGZvby9VVAUAAyoeaVN1eAsAAQToAwAABOgDAABQSwECHgMKAAAAAADZbKZE4Tl7
      zAQAAAAEAAAACwAYAAAAAAABAAAAtIE+AAAAZm9vL2Jhci50eHRVVAUAAyoeaVN1eAsAAQToAwAA
      BOgDAABQSwUGAAAAAAIAAgCbAAAAhwAAAAAA
      ')
  end

  describe 'with mocked source_artifact and component' do
    # mock @source_artifact
    before(:each) do
      @source_artifact_dir = Dir.mktmpdir
      @source_artifact = OpenStruct.new
      @source_artifact.path = @source_artifact_dir
      @source_artifact.zip_path = "#{@source_artifact_dir}/archive.zip"

      open(@source_artifact.zip_path, 'wb') { |f| f.write(OperationsPrepareConstants::ZipContents) }
    end
    after(:each) do
      FileUtils.remove_entry(@source_artifact_dir)
    end

    # mock @component
    before(:each) do
      @component = OpenStruct.new
      @component.name = 'a-component'
      @component.prepare_commands = []
    end

    before(:each) do
      @component_artifact_path = Dir.mktmpdir
      # mock ComponentArtifact
      @mockComponentArtifact = Struct.new(:component, :sha, :environment) do
        def files_path
          "#{path}/files"
        end
        def md5sum_path
          "#{path}/md5sum.txt"
        end
        def valid?
          false
        end
      end
      allow_any_instance_of(@mockComponentArtifact).to receive(:path).and_return(@component_artifact_path)

      stub_const('ComponentArtifact', @mockComponentArtifact)
    end

    after(:each) do
      FileUtils.remove_entry(@component_artifact_path)
    end

    subject { Operations::Prepare.new(@source_artifact, @component, 'production') }

    it { expect(subject.source_artifact).to equal(@source_artifact) }
    it { expect(subject.component).to equal(@component) }
    it { expect(subject.environment).to eq('production') }
    it { expect(subject.commands).to equal(@component.prepare_commands) }

    it 'should build in a temporary directory' do
      dir1 = Dir.pwd
      dir2 = nil

      subject.in_build_directory do
        dir2 = Dir.pwd
      end

      expect(dir2).not_to eq(dir1)
      expect(dir2).to match(/overview-manage-prepare-a-component/)
      expect(Dir.pwd).to eq(dir1)
    end

    it 'should extract the source_archive to the build directory' do
      subject.in_build_directory do
        contents = open('source/foo/bar.txt') { |f| f.read() }
        expect(contents.strip).to eq('baz')
      end
    end

    it 'should delete the temporary directory after prepare' do
      path = nil
      subject.in_build_directory { path = Dir.pwd }
      expect(File.exist?(path)).to eq(false)
    end

    it 'should run commands' do
      begin
        file = Tempfile.new('overview-manage-operations-prepare-spec')
        @component.prepare_commands = [ "echo 'foo' > #{file.path}" ]
        subject.run
        expect(file.read()).to eq("foo\n")
      ensure
        file.close!
      end
    end

    it 'should interpolate <%= environment %> and <%= component %>' do
      begin
        file = Tempfile.new('overview-manage-operations-prepare-spec')
        @component.prepare_commands = [ "echo <%= component.name[0...5] %> <%= environment %> > #{file.path}" ]
        subject.run
        expect(file.read()).to eq("a-com production\n")
      ensure
        file.close!
      end
    end

    it 'should not build when the build is already valid' do
      begin
        file = Tempfile.new('overview-manage-operations-prepare-spec')
        @component.prepare_commands = [ "echo 'foo' > #{file.path}" ]
        expect_any_instance_of(@mockComponentArtifact).to receive(:valid?).and_return(true)
        subject.run
      ensure
        file.close!
      end
    end

    describe 'with the ComponentArtifact .run returns' do
      subject do
        @component.prepare_commands = [
          'cp -a source/* component'
        ]
        @prepare = Operations::Prepare.new(@source_artifact, @component, 'production')
        @prepare.run
      end

      it 'should copy a file to the proper place from the build dir' do
        contents = open("#{subject.path}/files/foo/bar.txt", 'rb') { |f| f.read() }
        expect(contents.strip).to eq('baz')
      end

      it 'should write the file list to the md5sums file' do
        contents = open("#{subject.path}/md5sum.txt", 'rb') { |f| f.read() }
        expect(contents.strip).to eq('258622b1688250cb619f3c9ccaefb7eb *foo/bar.txt')
      end
    end
  end
end
