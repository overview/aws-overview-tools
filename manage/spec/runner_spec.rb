require 'runner'

require 'ostruct'

RSpec.describe Runner do
  before(:each) do
    @state = OpenStruct.new
  end

  before(:each) do
    @store = OpenStruct.new
  end

  subject { Runner.new(@state, @store) }

  it 'should have components_with_source' do
    @store.components = OpenStruct.new
    expect(@store.components).to receive(:with_source).with('foo').and_return([ 'x', 'y' ])
    expect(subject.components_with_source('foo')).to eq([ 'x', 'y' ])
  end

  describe 'machines_with_spec' do
    before(:each) do
      @machines = [
        double(environment: 'ENV1', type: 'TYPE1', ip_address: '10.1.1.1'),
        double(environment: 'ENV1', type: 'TYPE2', ip_address: '10.1.1.2'),
        double(environment: 'ENV2', type: 'TYPE1', ip_address: '10.1.1.3'),
        double(environment: 'ENV2', type: 'TYPE2', ip_address: '10.1.1.4'),
        double(environment: 'ENV2', type: 'TYPE2', ip_address: '10.1.1.5'),
      ]
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
      expect(subject.machines_with_spec('ENV2.TYPE2')).to eq([ @machines[3], @machines[4] ])
    end

    it 'should filter by environment, type and IP' do
      expect(subject.machines_with_spec('ENV2.TYPE2.10.1.1.4')).to eq([ @machines[3] ])
    end
  end
end
