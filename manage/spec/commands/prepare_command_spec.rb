require 'commands/prepare_command'

RSpec.describe Commands::PrepareCommand do
  before(:each) do
    @source = Struct.new(:name).new('source')
    @source_at_version = Struct.new(:source, :version).new(@source, 'abcdef')
  end
  before(:each) do
    @source_artifact = Struct.new(:source).new(@source.name)
  end
  before(:each) do
    @buildOperationClass = Struct.new(:source, :version)
    stub_const('Operations::Build', @buildOperationClass)
  end
  before(:each) do
    @prepareOperationClass = Struct.new(:source_artifact, :component)
    @mock_prepare_operation = @prepareOperationClass.new('source_artifact', 'component')
    stub_const('Operations::Prepare', @prepareOperationClass)
  end
  before(:each) do
    @componentClass = Struct.new(:source)
    @component1 = @componentClass.new('source')
    @component2 = @componentClass.new('source')
    @components = [ @component1, @component2 ]
    @runner = double()
    allow(@runner).to receive(:components_with_source).with('source').and_return(@components)
  end

  it 'should build once and prepare each component' do
    expect_any_instance_of(@buildOperationClass).to receive(:run).and_return(@source_artifact)
    expect(@prepareOperationClass).to receive(:new).with(@source_artifact, @component1).and_return(@mock_prepare_operation)
    expect(@prepareOperationClass).to receive(:new).with(@source_artifact, @component2).and_return(@mock_prepare_operation)
    expect(@mock_prepare_operation).to receive(:run).twice
    subject.run(@runner, @source_at_version)
  end
end
