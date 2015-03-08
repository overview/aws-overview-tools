require 'arguments/environment'

RSpec.describe Arguments::Environment do
  it { expect(subject.name).to eq('ENVIRONMENT') }
  it { expect(subject.description).to match(/staging/) }

  describe 'with a runner' do
    before(:each) do
      @runner = double()
    end

    it 'should parse a valid environment' do
      ret = subject.parse(@runner, 'production')
      expect(ret).to eq('production')
    end

    it 'should throw ArgumentError on invalid environment' do
      expect{ subject.parse(@runner, 'not-production') }.to raise_error(ArgumentError)
    end
  end
end
