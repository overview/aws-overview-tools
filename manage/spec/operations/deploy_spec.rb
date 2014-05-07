require 'operations/deploy'

RSpec.describe Operations::Deploy do
  before(:each) do
    @component = double('Component', deploy_commands: [ 'echo foo' ])
    @machine = double('Machine')
    @shell = double('Shell')
    allow(@machine).to receive(:shell).and_yield(@shell)
  end

  subject { Operations::Deploy.new(@component, @machine) }

  it 'should run the deploy commands' do
    expect(@machine).to receive(:shell).and_yield(@shell)
    expect(@shell).to receive(:exec).with('echo foo').and_return(true)
    expect(subject.run).to be(true)
  end
end
