require 'machine_type'

require 'yaml'

RSpec.describe MachineType do
  subject {
    yaml = YAML.load('---
      start_commands:
        - start
      stop_commands:
        - stop
      restart_commands:
        - restart
      ')
    MachineType.from_yaml('web', yaml)
  }

  it { expect(subject.name).to eq('web') }
  it { expect(subject.start_commands).to eq(['start']) }
  it { expect(subject.stop_commands).to eq(['stop']) }
  it { expect(subject.restart_commands).to eq(['restart']) }
end
