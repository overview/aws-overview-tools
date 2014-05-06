require 'component'

require 'yaml'

RSpec.describe Component do
  it 'should initialize from a hash' do
    subject = Component.new(name: 'name', source: 'source', prepare_commands: [ 'prepare' ], post_install_commands: [ 'post_install' ])
    expect(subject.name).to eq('name')
    expect(subject.source).to eq('source')
    expect(subject.prepare_commands).to eq(['prepare'])
    expect(subject.post_install_commands).to eq(['post_install'])
  end

  it 'should initialize from YAML' do
    yaml = YAML.load("---
      name:
        source: source
        prepare_commands:
          - prepare
        post_install_commands:
          - post_install
      ")
    subject = Component.from_yaml('name', yaml['name'])
    expect(subject.name).to eq('name')
    expect(subject.source).to eq('source')
    expect(subject.prepare_commands).to eq(['prepare'])
    expect(subject.post_install_commands).to eq(['post_install'])
  end

  describe 'with a typical Component' do
    subject { Component.new(name: 'name', source: 'source', prepare_commands: [ 'prepare' ], post_install_commands: [ 'post_install' ]) }

    it { expect(subject.install_path).to eq('/opt/overview/name') }
    it { expect(subject.prepare_path('abcdef123456', 'production')).to eq('/opt/overview/manage/component-artifacts/name/abcdef123456/production') }
  end
end
