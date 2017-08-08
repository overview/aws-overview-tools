require 'stores/sources'

RSpec.describe Stores::Sources do
  before(:each) do
    @sourceClass = Struct.new(:name, :yaml) do
      def self.from_yaml(name, yaml)
        self.new(name, yaml)
      end
    end
    stub_const('Source', @sourceClass)
  end

  subject {
    yaml = YAML.load('---
      overview-server:
        url: https://github.com/overview/overview-server.git

      aws-overview-config:
        url: https://github.com/overview/aws-overview-config.git
      ')
    Stores::Sources.from_yaml(yaml)
  }

  it { expect(subject['overvi-server']).to be_nil }
  it { expect(subject['overview-server']).to be_a(@sourceClass) }
  it { expect(subject['overview-server'].name).to eq('overview-server') }
  it { expect(subject['overview-server'].yaml['url']).to eq('https://github.com/overview/overview-server.git') }
end
