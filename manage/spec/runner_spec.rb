require 'runner'

RSpec.describe Runner do
  before(:each) do
    @state = double()
  end

  before(:each) do
    @store = double()
  end

  before(:each) do
    @config = {}
  end

  before(:each) do
    @some_machines = [
      double(environment: 'ENV1', type: 'TYPE1', ip_address: '10.1.1.1'),
      double(environment: 'ENV1', type: 'TYPE2', ip_address: '10.1.1.2'),
      double(environment: 'ENV2', type: 'TYPE1', ip_address: '10.1.1.3'),
      double(environment: 'ENV2', type: 'TYPE2', ip_address: '10.1.1.4'),
      double(environment: 'ENV2', type: 'TYPE2', ip_address: '10.1.1.5'),
    ]
  end

  subject {
    Runner.new(@state, @store, @config)
  }

  it 'should have remote_build_config' do
    @config['remote_build'] = 'hello'
    expect(subject.remote_build_config).to eq('hello')
  end

  describe 'machines_with_spec' do
    before(:each) do
      @machines = @some_machines
      allow(subject).to receive(:machines).and_return(@machines)
    end

    it 'should return [] when there are no machines' do
      @machines = []
      expect(subject.machines_with_spec('production')).to eq([])
    end

    it 'should throw ArgumentError when there is no environment' do
      expect{ subject.machines_with_spec('') }.to raise_error(ArgumentError)
    end

    it 'should filter by environment' do
      expect(subject.machines_with_spec('ENV1')).to eq([ @machines[0], @machines[1] ])
    end

    it 'should filter by environment and type' do
      expect(subject.machines_with_spec('ENV2/TYPE2')).to eq([ @machines[3], @machines[4] ])
    end

    it 'should filter by environment, type and IP' do
      expect(subject.machines_with_spec('ENV2/TYPE2/10.1.1.4')).to eq([ @machines[3] ])
    end
  end
end
