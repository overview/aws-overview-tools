require 'machine_type'

require 'yaml'

RSpec.describe MachineType do
  subject {
    yaml = YAML.load('---
      components:
        - config-web
        - frontend
      ')
    MachineType.from_yaml('web', yaml)
  }

  it { expect(subject.name).to eq('web') }
  it { expect(subject.components).to eq(['config-web', 'frontend']) }
end
