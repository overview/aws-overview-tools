require 'machine_shell'
require 'command_executors/base'

require('net/ssh')
require('net/scp')

RSpec.describe MachineShell do
  before(:each) do
    @ssh = instance_double('Net::SSH::Connection::Session')
    allow(@ssh).to receive(:host).and_return('10.1.1.1')
  end

  subject { MachineShell.new(@ssh) }

  describe '#component_artifacts_with_timestamps' do
    it 'should return an empty list when there are none' do
      expect(subject).to receive(:exec_command)
        .with("find /opt/overview/manage/component-artifacts -maxdepth 3 -mindepth 3 -type d -printf \\%P/\\%T@\'\n\'")
        .and_return("\n")
      expect(subject.component_artifacts_with_timestamps).to eq([])
    end

    it 'should parse each line' do
      expect(subject).to receive(:exec_command)
        .and_return("documentset-worker/ca15e15a8f1a88a89d94ebd5cc149b09a67cdb27/production/1400083391.3164997570\ndocumentset-worker/ca15e15a8f1a88a89d94ebd5cc149b09a67cdb27/staging/1400077866.6999931740\n")
      result = subject.component_artifacts_with_timestamps
      expect(result.length).to eq(2)
      expect(result[0].component_artifact.to_s).to eq(ComponentArtifact.new('documentset-worker', 'ca15e15a8f1a88a89d94ebd5cc149b09a67cdb27', 'production').to_s)
      expect(result[0].timestamp).to eq(Time.at(1400083391.3164997570))
    end
  end

  describe '#source_artifacts_with_timestamps' do
    it 'should return an empty list when there are none' do
      expect(subject).to receive(:exec_command)
        .with("find /opt/overview/manage/source-artifacts -maxdepth 2 -mindepth 2 -type d -printf \\%P/\\%T@\'\n\'")
        .and_return("\n")
      expect(subject.source_artifacts_with_timestamps).to eq([])
    end

    it 'should parse each line' do
      expect(subject).to receive(:exec_command)
        .and_return("aws-overview-config/f6088056f03cf2a9d4d47a8d84cb199f510495dd/1400079088.4642294820\noverview-server/ca15e15a8f1a88a89d94ebd5cc149b09a67cdb27/1400077848.5319843790\n")
      result = subject.source_artifacts_with_timestamps
      expect(result.length).to eq(2)
      expect(result[0].source_artifact.to_s).to eq(SourceArtifact.new('aws-overview-config', 'f6088056f03cf2a9d4d47a8d84cb199f510495dd').to_s)
      expect(result[0].timestamp).to eq(Time.at(1400079088.4642294820))
    end
  end

  it 'should rm_rf successfully' do
    expect(subject).to receive(:exec_command).with('rm -rf /foo/bar').and_return(true)
    expect(subject.rm_rf('/foo/bar')).to be(true)
  end

  it 'should fail an rm_rf' do
    # We won't test _all_ the failures, since we know they're all implemented
    # the same way.
    expect(subject).to receive(:exec_command).with('rm -rf /foo/bar').and_raise(Exception.new)
    expect{ subject.rm_rf('/foo/bar') }.to raise_error(Exception)
  end

  it 'should readlink successfully' do
    expect(subject).to receive(:exec_command).with('readlink /opt/overview/config-common').and_return('/opt/overview/manage/component-artifacts/config-common/f04272d36b00a88d1390a06d588f086386dfded1/staging/files')
    expect(subject.readlink('/opt/overview/config-common')).to eq('/opt/overview/manage/component-artifacts/config-common/f04272d36b00a88d1390a06d588f086386dfded1/staging/files')
  end

  it 'should return nil when calling readlink on an invalid link' do
    expect(subject).to receive(:exec_command).and_raise(CommandExecutors::CommandFailedException.new("link does not exist"))
    expect(subject.readlink('/opt/overview/config-common')).to eq(nil)
  end

  it 'should mkdir_p successfully' do
    expect(subject).to receive(:exec_command).with('mkdir -p /foo/bar').and_return(true)
    expect(subject.mkdir_p('/foo/bar')).to be(true)
  end

  it 'should ln_sfT successfully' do
    expect(subject).to receive(:exec_command).with('ln -sfT /tmp/foo /tmp/bar').and_return(true)
    expect(subject.ln_sfT('/tmp/foo', '/tmp/bar')).to be(true)
  end

  it 'should md5sum successfully' do
    expect(subject).to receive(:exec_command).with('md5sum -b archive.zip').and_return("e3a6ac30651ade2607a7870e8551c371 *archive.zip\n")
    expect(subject.md5sum('archive.zip')).to eq('e3a6ac30651ade2607a7870e8551c371')
  end

  it 'should handle md5sum errors' do
    expect(subject).to receive(:exec_command).with('md5sum -b archive.zi').and_return("md5sum: archive.zi: No such file or directory\n")
    expect{ subject.md5sum('archive.zi') }.to raise_error(CommandExecutors::CommandFailedException)
  end

  it 'should check is_component_artifact_valid? => true' do
    expect(subject).to receive(:exec_command).with('(cd /foo/bar/files && md5sum --status -c ../md5sum.txt)').and_return(true)
    expect(subject.is_component_artifact_valid?('/foo/bar')).to be(true)
  end

  it 'should check is_component_artifact_valid? => false' do
    expect(subject).to receive(:exec_command).and_raise(CommandExecutors::CommandFailedException.new("Command returned non-zero status code"))
    expect(subject.is_component_artifact_valid?('/foo/bar')).to be(false)
  end

  it 'should return true from upload_r' do
    scp = instance_double('Net::SCP')
    expect(@ssh).to receive(:scp).and_return(scp)
    expect(scp).to receive(:upload!).with('/foo/bar', '/foo/baz', recursive: true).and_return('undefined')
    expect(subject.upload_r('/foo/bar', '/foo/baz')).to be(true)
  end

  it 'should return true from download' do
    scp = instance_double('Net::SCP')
    expect(@ssh).to receive(:scp).and_return(scp)
    expect(scp).to receive(:download!).with('/foo/bar', '/foo/baz').and_return('undefined')
    expect(subject.download('/foo/bar', '/foo/baz')).to be(true)
  end
end
