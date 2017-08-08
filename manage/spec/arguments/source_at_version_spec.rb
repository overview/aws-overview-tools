require 'arguments/source_at_version'

require 'ostruct'

RSpec.describe Arguments::SourceAtVersion do
  it { expect(subject.name).to eq('SOURCE@VERSION') }
  it { expect(subject.description).to match(/overview-server@master/) }

  describe 'with a runner' do
    before(:each) do
      @runner = OpenStruct.new
      @runner.sources = {
        'overview-server' => 'foo'
      }
    end

    #it 'should parse a valid source+version' do
    #  ret = subject.parse(@runner, 'overview-server@abcdef123456')
    #  expect(ret.source).to eq('overview-server')
    #  expect(ret.version).to eq('abcdef123456')
    #end

    #it 'should parse a source with no version as version master' do
    #  ret = subject.parse(@runner, 'overview-server')
    #  expect(ret.source).to eq('overview-server')
    #  expect(ret.version).to eq('master')
    #end

    it 'should throw ArgumentError on invalid version' do
      expect{ subject.parse(@runner, 'overview-server@@@') }.to raise_error(ArgumentError)
    end

    it 'should throw ArgumentError if the source does not exist' do
      expect{ subject.parse(@runner, 'overviw-server@abcdef123456') }.to raise_error(ArgumentError)
    end
  end
end
