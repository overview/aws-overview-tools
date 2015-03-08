require 'machine_type'
require 'stores/machine_types'

RSpec.describe Stores::MachineTypes do
  subject {
    yaml = YAML.load(%{---
      web:
        start_commands:
          - do something

      worker:
        stop_commands:
          - do something else
      })
    Stores::MachineTypes.from_yaml(yaml)
  }

  it { expect(subject['we']).to be_nil }
  it { expect(subject['web']).to be_a(MachineType) }
  it { expect(subject['web'].name).to eq('web') }
  it { expect(subject['web'].start_commands).to eq(['do something']) }
  it { expect(subject['worker'].stop_commands).to eq(['do something else']) }
end
