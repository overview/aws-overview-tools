require 'runner'

require 'aws/ec2'

RSpec.describe Runner do
  before(:each) do
    @state = double()
  end

  before(:each) do
    @store = double(components: [])
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

  it 'should have components_with_source' do
    expect(@store.components).to receive(:with_source).with('foo').and_return([ 'x', 'y' ])
    expect(subject.components_with_source('foo')).to eq([ 'x', 'y' ])
  end

  describe 'environments' do
    before(:each) do
      allow(subject).to receive(:machines).and_return(@some_machines)
    end

    it 'should be initialized based on the machines' do
      expect(subject.environments).to eq(Set.new(['ENV1', 'ENV2']))
    end
  end

  it 'should have remote_build_config' do
    @config['remote_build'] = 'hello'
    expect(subject.remote_build_config).to eq('hello')
  end

  describe 'connect_to_ec2' do
    before(:each) do
      @env = {}
      stub_const('ENV', @env)
    end

    before(:each) do
      @ec2Class = class_double('AWS::EC2')
      stub_const('AWS::EC2', @ec2Class)
      @ec2 = instance_double('AWS::EC2')
      allow(@ec2Class).to receive(:new).and_return(@ec2)
    end

    it 'should connect to ec2 when AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set' do
      @env['AWS_ACCESS_KEY_ID'] = 'ACCESS_KEY'
      @env['AWS_SECRET_ACCESS_KEY'] = 'SECRET_ACCESS_KEY'
      expect(@ec2Class).to receive(:new).with(
        access_key_id: 'ACCESS_KEY',
        secret_access_key: 'SECRET_ACCESS_KEY'
      ).and_return(@ec2)
      expect(subject.connect_to_ec2).to equal(@ec2)
    end

    it 'should not connect to ec2 when AWS_ACCESS_KEY_ID is unset' do
      @env['AWS_SECRET_ACCESS_KEY'] = 'SECRET_ACCESS_KEY'
      expect(@ec2Class).not_to receive(:new)
      expect{ subject.connect_to_ec2 }.to raise_error
      begin; subject.connect_to_ec2; rescue; end
    end

    it 'should not connect to ec2 when AWS_SECRET_ACCESS_KEY is unset' do
      @env['AWS_ACCESS_KEY_ID'] = 'ACCESS_KEY'
      expect(@ec2Class).not_to receive(:new)
      expect{ subject.connect_to_ec2 }.to raise_error
      begin; subject.connect_to_ec2; rescue; end
    end
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
