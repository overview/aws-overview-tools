require 'machine'

require 'net/ssh'

RSpec.describe Machine do
  subject { Machine.new(environment: 'production', type: 'web', ip_address: '10.1.2.3') }

  it { expect(subject.environment).to eq('production') }
  it { expect(subject.type).to eq('web') }
  it { expect(subject.ip_address).to eq('10.1.2.3') }

  describe '.shell' do
    it 'should start a MachineShell with an SSH session' do
      ssh = double('Net::SSH::Connection::Session')
      expect(Net::SSH).to receive(:start).with('10.1.2.3', 'ubuntu').and_yield(ssh)
      subject.shell do |x|
        expect(x).to equal(ssh)
      end
    end
  end
end
