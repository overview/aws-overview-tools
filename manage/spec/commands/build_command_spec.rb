require 'commands/build_command'

RSpec.describe Commands::BuildCommand do
  before(:each) { @runner = double() }
  before(:each) {
    @pipelineCommandRunner = double()
    @pipelineCommandRunnerClass = double()
    stub_const('PipelineCommandRunner', @pipelineCommandRunnerClass)
    allow(@pipelineCommandRunnerClass).to receive(:new).with(@runner).and_return(@pipelineCommandRunner)
  }

  it 'should invoke PipelineCommandRunner.build' do
    expect(@pipelineCommandRunner).to receive(:build).with('source', 'version')
    subject.run(@runner, double(source: 'source', version: 'version'))
  end
end
