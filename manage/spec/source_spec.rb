require 'source'

require 'yaml'

module MockGit
  class Base
    def self.bare(path, opts = {})
      self.new
    end

    def self.clone(repository, name, opts = {})
      self.new
    end

    def fetch
    end
  end
end

RSpec.describe 'Source' do
  before(:each) do
    @subject = Source.new(name: 'source', url: 'https://github.com/example/example-source.git')
    stub_const('Git', MockGit, transfer_nested_contents: true)
  end

  it 'should serialize' do
    expect(@subject.to_hash['name']).to eq(@subject.name)
    expect(@subject.to_hash['url']).to eq(@subject.url)
  end

  it 'should deserialize' do
    source2 = Source.new(@subject)
    expect(source2.to_hash).to eq(@subject.to_hash)
  end

  it 'should initialize from YAML' do
    yaml = YAML.load("---
      overview-server:
        url: https://github.com/overview/overview-server.git
      ")
    source = Source.from_yaml('key', yaml['overview-server'])
    expect(source.name).to eq('key')
    expect(source.url).to eq('https://github.com/overview/overview-server.git')
  end
end
