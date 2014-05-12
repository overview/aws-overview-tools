require 'commands/prepare_command'

RSpec.describe Commands::PrepareCommand do
  before(:each) {
    @runner = double()
  }
  before(:each) {
    @pipelineCommandRunner = double()
    @pipelineCommandRunnerClass = double()
    stub_const('PipelineCommandRunner', @pipelineCommandRunnerClass)
    allow(@pipelineCommandRunnerClass).to receive(:new).with(@runner).and_return(@pipelineCommandRunner)
  }

  it 'should invoke PipelineCommandRunner.build' do
    expect(@pipelineCommandRunner).to receive(:prepare).with('source', 'version', 'production')
    subject.run(@runner, double(source: 'source', version: 'version'), 'production')
  end
end
