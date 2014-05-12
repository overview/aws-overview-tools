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

  it 'should ln_sf successfully' do
    expect(subject).to receive(:exec_command).with('ln -sf /tmp/foo /tmp/bar').and_return(true)
    expect(subject.ln_sf('/tmp/foo', '/tmp/bar')).to be(true)
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
end
