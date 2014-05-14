require 'machine_shell'

require('net/ssh')
require('net/scp')

RSpec.describe MachineShell do
  before(:each) do
    @ssh = instance_double('Net::SSH::Connection::Session')
    allow(@ssh).to receive(:host).and_return('10.1.1.1')
  end

  subject { MachineShell.new(@ssh) }

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

  it 'should mkdir_p successfully' do
    expect(subject).to receive(:exec_command).with('mkdir -p /foo/bar').and_return(true)
    expect(subject.mkdir_p('/foo/bar')).to be(true)
  end

  it 'should ln_sfT successfully' do
    expect(subject).to receive(:exec_command).with('ln -sfT /tmp/foo /tmp/bar').and_return(true)
    expect(subject.ln_sfT('/tmp/foo', '/tmp/bar')).to be(true)
  end

  it 'should md5sum successfully' do
    expect(@ssh).to receive(:exec!).with('md5sum -b archive.zip').and_return("e3a6ac30651ade2607a7870e8551c371 *archive.zip\n")
    expect(subject.md5sum('archive.zip')).to eq('e3a6ac30651ade2607a7870e8551c371')
  end

  it 'should handle md5sum errors' do
    expect(@ssh).to receive(:exec!).with('md5sum -b archive.zi').and_return("md5sum: archive.zi: No such file or directory\n")
    expect{ subject.md5sum('archive.zi') }.to raise_error(MachineShell::CommandFailedException)
  end

  it 'should check is_component_artifact_valid? => true' do
    expect(subject).to receive(:exec_command).with('(cd /foo/bar/files && md5sum --status -c ../md5sum.txt)').and_return(true)
    expect(subject.is_component_artifact_valid?('/foo/bar')).to be(true)
  end

  it 'should check is_component_artifact_valid? => false' do
    expect(subject).to receive(:exec_command).and_raise(MachineShell::CommandFailedException.new("Command returned non-zero status code"))
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
