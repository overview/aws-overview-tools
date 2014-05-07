require 'operations/publish'

require 'fileutils'
require 'ostruct'

RSpec.describe Operations::Publish do
  # Mock @component_artifact
  before(:each) do
    @component_artifact = OpenStruct.new
    @component_artifact.path = '/tmp/path'
    @component_artifact.md5sum_path = '/tmp/path/md5sum.txt'
    @component_artifact.files_path = '/tmp/path/files'
  end

  # Mock @machine
  before(:each) do
    @machine = OpenStruct.new
  end

  subject { Operations::Publish.new(@component_artifact, @machine) }

  it { expect(subject.component_artifact).to equal(@component_artifact) }
  it { expect(subject.machine).to equal(@machine) }

  it 'should skip everything when the artifact is already on the machine' do
    @shell = double()
    expect(@machine).to receive(:shell).and_yield(@shell)
    expect(@shell).to receive(:is_component_artifact_valid?).with('/tmp/path').and_return(true)
    expect(subject.run).to be(true)
  end

  describe 'when the artifact is not already on the machine' do
    before(:each) do
      @shell = double()
      expect(@machine).to receive(:shell).and_yield(@shell)
      expect(@shell).to receive(:is_component_artifact_valid?).with('/tmp/path').and_return(false)
    end

    it 'should rm_rf, mkdir and copy the directory' do
      expect(@shell).to receive(:rm_rf).with('/tmp/path').and_return(true)
      expect(@shell).to receive(:mkdir_p).with('/tmp').and_return(true)
      expect(@shell).to receive(:upload_r).with('/tmp/path', '/tmp/path').and_return(true)
      expect(subject.run).to be(true)
    end

    it 'should fail if a command fails' do
      expect(@shell).to receive(:rm_rf).with('/tmp/path').and_return(true)
      expect(@shell).to receive(:mkdir_p).with('/tmp').and_return(false)
      expect(subject.run).to be(false)
    end
  end
end
