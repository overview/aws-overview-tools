require 'arguments/machines'

RSpec.describe Arguments::Machines do
  it { expect(subject.name).to eq('MACHINES') }
  it { expect(subject.description).to match(/staging.web/) }

  describe 'with a runner' do
    before(:each) do
      @runner = double()
    end

    it 'should parse a valid machine spec' do
      expect(@runner).to receive(:machines_with_spec).with('a.b').and_return([ double() ])
      ret = subject.parse(@runner, 'a.b')
      expect(ret).to eq('a.b')
    end

    it 'should raise an ArgumentError from the runner' do
      expect(@runner).to receive(:machines_with_spec).and_raise(ArgumentError.new)
      expect{ subject.parse(@runner, 'a.b') }.to raise_error(ArgumentError)
    end

    it 'should raise ArgumentError if there are no machines' do
      expect(@runner).to receive(:machines_with_spec).and_return([])
      expect{ subject.parse(@runner, 'a.b') }.to raise_error(ArgumentError)
    end
  end
end
