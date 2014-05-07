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
end
