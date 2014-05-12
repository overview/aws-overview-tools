require 'commands/install_command'

RSpec.describe Commands::InstallCommand do
  before(:each) {
    @runner = double()
    @pipelineCommandRunner = double()
    @pipelineCommandRunnerClass = double()
    stub_const('PipelineCommandRunner', @pipelineCommandRunnerClass)
    allow(@pipelineCommandRunnerClass).to receive(:new).with(@runner).and_return(@pipelineCommandRunner)
  }

  it 'should invoke PipelineCommandRunner.build' do
    expect(@pipelineCommandRunner).to receive(:install).with('source', 'version', 'production')
    subject.run(@runner, double(source: 'source', version: 'version'), 'production')
  end
end