require 'operations/deploy'

RSpec.describe Operations::Deploy do
  before(:each) do
    @component = double('Component', name: 'component', deploy_commands: [ 'echo foo' ])
    @machine = double('Machine', environment: 'environment')
    @shell = double('Shell')
    allow(@machine).to receive(:shell).and_yield(@shell)
  end

  subject { Operations::Deploy.new(@component, @machine) }

  it 'should run the deploy commands' do
    expect(@machine).to receive(:shell).and_yield(@shell)
    expect(@shell).to receive(:exec).with('echo foo').and_return(true)
    expect(subject.run).to be(true)
  end

  it 'should interpolate <%= component %> and <%= machine %>' do
    allow(@component).to receive(:deploy_commands).and_return(['echo <%= component.name %> <%= machine.environment %>'])
    expect(@machine).to receive(:shell).and_yield(@shell)
    expect(@shell).to receive(:exec).with('echo component environment').and_return(true)
    expect(subject.run).to be(true)
  end
end
