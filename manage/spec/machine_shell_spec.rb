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

  it 'should mkdir_p successfully' do
    expect(subject).to receive(:exec_command).with('mkdir -p /foo/bar').and_return(true)
    expect(subject.mkdir_p('/foo/bar')).to be(true)
  end

  it 'should md5sum successfully' do
    expect(subject).to receive(:exec_command).with('md5sum -b archive.zip').and_return("e3a6ac30651ade2607a7870e8551c371 *archive.zip\n")
    expect(subject.md5sum('archive.zip')).to eq('e3a6ac30651ade2607a7870e8551c371')
  end

  it 'should handle md5sum errors' do
    expect(subject).to receive(:exec_command).with('md5sum -b archive.zi').and_return("md5sum: archive.zi: No such file or directory\n")
    expect{ subject.md5sum('archive.zi') }.to raise_error(CommandExecutors::CommandFailedException)
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
