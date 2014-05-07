require 'machine_shell'

require('net/ssh')
require('net/scp')

RSpec.describe MachineShell do
  before(:each) do
    @ssh = instance_double('Net::SSH::Connection::Session')
  end

  subject { MachineShell.new(@ssh) }

  it 'should rm_rf successfully' do
    expect(@ssh).to receive(:exec!).with('rm -rf /foo/bar > /dev/null 2>&1; echo $?').and_return("0\n")
    expect(subject.rm_rf('/foo/bar')).to be(true)
  end

  it 'should fail an rm_rf' do
    # We won't test _all_ the failures, since we know they're all implemented
    # the same way.
    expect(@ssh).to receive(:exec!).with('rm -rf /foo/bar > /dev/null 2>&1; echo $?').and_return("1\n")
    expect(subject.rm_rf('/foo/bar')).to be(false)
  end

  it 'should mkdir_p successfully' do
    expect(@ssh).to receive(:exec!).with('mkdir -p /foo/bar > /dev/null 2>&1; echo $?').and_return("0\n")
    expect(subject.mkdir_p('/foo/bar')).to be(true)
  end

  it 'should ln_sf successfully' do
    expect(@ssh).to receive(:exec!).with('ln -sf /tmp/foo /tmp/bar > /dev/null 2>&1; echo $?').and_return("0\n")
    expect(subject.ln_sf('/tmp/foo', '/tmp/bar')).to be(true)
  end

  it 'should check is_component_artifact_valid?' do
    expect(@ssh).to receive(:exec!).with('(cd /foo/bar/files && md5sum -c ../md5sum.txt) > /dev/null 2>&1; echo $?').and_return("0\n")
    expect(subject.is_component_artifact_valid?('/foo/bar')).to be(true)
  end

  it 'should return true from upload_r' do
    scp = instance_double('Net::SCP')
    expect(@ssh).to receive(:scp).and_return(scp)
    expect(scp).to receive(:upload!).with('/foo/bar', '/foo/baz', recursive: true).and_return('undefined')
    expect(subject.upload_r('/foo/bar', '/foo/baz')).to be(true)
  end
end
