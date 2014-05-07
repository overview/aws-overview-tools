require 'stores/machine_types'

RSpec.describe Stores::MachineTypes do
  before(:each) do
    @machineTypeClass = Struct.new(:name, :yaml) do
      def self.from_yaml(name, yaml)
        self.new(name, yaml)
      end
    end
    stub_const('MachineType', @machineTypeClass)
  end

  subject {
    yaml = YAML.load(%{---
      web:
        components:
          - config-web
          - frontend

      worker:
        components:
          - config-worker
          - worker
          - documentset-worker
          - message-broker
      })
    Stores::MachineTypes.from_yaml(yaml)
  }

  it { expect(subject['we']).to be_nil }
  it { expect(subject['web']).to be_a(@machineTypeClass) }
  it { expect(subject['web'].name).to eq('web') }
  it { expect(subject['web'].yaml['components']).to eq(['config-web', 'frontend']) }
end
