require 'store'

RSpec.describe Store do
  before(:each) do
    @machineTypesClass = Struct.new(:yaml) do
      def self.from_yaml(yaml)
        self.new(yaml)
      end
    end
    stub_const('Stores::MachineTypes', @machineTypesClass)
  end

  before(:each) do
    @sourcesClass = Struct.new(:yaml) do
      def self.from_yaml(yaml)
        self.new(yaml)
      end
    end
    stub_const('Stores::Sources', @sourcesClass)
  end

  subject {
    yaml = YAML.load(%{---
      sources:
        overview-server:
          foo: bar
      machine_types:
        web:
          bar: baz
      })
    Store.from_yaml(yaml)
  }

  it { expect(subject.machine_types).to be_a(@machineTypesClass) }
  it { expect(subject.machine_types.yaml).to eq({ 'web' => { 'bar' => 'baz' } }) }
  it { expect(subject.sources).to be_a(@sourcesClass) }
  it { expect(subject.sources.yaml).to eq({ 'overview-server' => { 'foo' => 'bar' } }) }
end
