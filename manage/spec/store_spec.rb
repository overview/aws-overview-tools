require 'store'

RSpec.describe Store do
  before(:each) do
    @componentsClass = Struct.new(:yaml) do
      def self.from_yaml(yaml)
        self.new(yaml)
      end
    end
    stub_const('Stores::Components', @componentsClass)
  end

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
      components:
        frontend:
          foo: baz
      machine_types:
        web:
          bar: baz
      })
    Store.from_yaml(yaml)
  }

  it { expect(subject.components).to be_a(@componentsClass) }
  it { expect(subject.components.yaml).to eq({ 'frontend' => { 'foo' => 'baz' } }) }
  it { expect(subject.machine_types).to be_a(@machineTypesClass) }
  it { expect(subject.machine_types.yaml).to eq({ 'web' => { 'bar' => 'baz' } }) }
  it { expect(subject.sources).to be_a(@sourcesClass) }
  it { expect(subject.sources.yaml).to eq({ 'overview-server' => { 'foo' => 'bar' } }) }
end
