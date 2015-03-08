require 'machine'

require 'net/ssh'

RSpec.describe Machine do
  subject {
    type = double(name: 'web', start_commands: [ 'start' ], stop_commands: [ 'stop' ], restart_commands: [ 'restart' ])
    Machine.new(environment: 'production', type: type, ip_address: '10.1.2.3')
  }

  it { expect(subject.environment).to eq('production') }
  it { expect(subject.ip_address).to eq('10.1.2.3') }
  it { expect(subject.start_commands).to eq(['start']) }
  it { expect(subject.stop_commands).to eq(['stop']) }
  it { expect(subject.restart_commands).to eq(['restart']) }

  describe '.shell' do
    before(:each) do
      @ssh = double('Net::SSH::Connection::Session')
      allow(Net::SSH).to receive(:start).and_return(@ssh)

      @machineShellType = Struct.new(:ssh)
      stub_const('MachineShell', @machineShellType)
    end

    it 'should start a MachineShell with an SSH session' do
      expect(Net::SSH).to receive(:start).with('10.1.2.3', 'ubuntu').and_return(@ssh)
      subject.shell do |x|
        expect(x).to be_a(@machineShellType)
        expect(x.ssh).to eq(@ssh)
      end
    end

    it 'should store one MachineShell and use it for repeated blocks' do
      shell1 = nil
      subject.shell do |shell|
        shell1 = shell
      end

      subject.shell do |shell|
        expect(shell).to equal(shell1)
      end
    end
  end
end
