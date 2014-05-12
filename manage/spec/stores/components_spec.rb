require 'stores/components'

RSpec.describe Stores::Components do
  before(:each) do
    @componentClass = Struct.new(:name, :yaml) do
      def self.from_yaml(name, yaml)
        self.new(name, yaml)
      end
      def source
        self.yaml['source']
      end
    end
    stub_const('Component', @componentClass)
  end

  subject {
    yaml = YAML.load(%{---
      frontend:
        source: overview-server
        prepare_commands:
          - "(cd source/libs && xargs -I '{}' -a ../<%= component.name %>/classpath.txt cp '{}' ../../component)"
        deploy_commands:
          - /opt/overview/config-web/scripts/start.sh
      worker:
        source: overview-server2
        prepare_commands:
          - "(cd source/libs && xargs -I '{}' -a ../<%= component.name %>/classpath.txt cp '{}' ../../component)"
        deploy_commands:
          - /opt/overview/config-worker/scripts/start.sh
      })
    Stores::Components.from_yaml(yaml)
  }

  it { expect(subject['fronten']).to be_nil }
  it { expect(subject['frontend']).to be_a(@componentClass) }
  it { expect(subject['frontend'].name).to eq('frontend') }
  it { expect(subject['frontend'].yaml['source']).to eq('overview-server') }
  it { expect(subject.with_source('not-a-real-source')).to eq([]) }
  it { expect(subject.with_source('overview-server2').map(&:name)).to eq([ 'worker' ]) }
end
