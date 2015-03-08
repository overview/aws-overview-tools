require 'pipeline_command_runner'

require 'operations/build'
require 'ostruct'

RSpec.describe PipelineCommandRunner do
  describe 'build' do
    before(:each) do
      @artifactType = Struct.new(:source, :sha, :s3_bucket)
      stub_const('Artifact', @artifactType)
      allow_any_instance_of(@artifactType).to receive(:valid?).and_return(false)

      @s3Bucket = double()

      @source = double(name: 'source-name', artifact_bucket: @s3Bucket)
      allow(@source).to receive(:fetch)
      allow(@source).to receive(:revparse).with('version').and_return('version')

      @buildOperationType = class_double('Operations::Build')
      stub_const('Operations::Build', @buildOperationType)
      @build_operation = instance_double('Operations::Build', source: @source, treeish: 'version')
      allow(@buildOperationType).to receive(:new).and_return(@build_operation)
      allow(@build_operation).to receive(:run).and_return(@source)

      @runner = double(
        sources: { 'source' => @source },
        connect_to_ec2: lambda { nil },
        remote_build_config: {}
      )
    end

    subject { PipelineCommandRunner.new(@runner) }

    it 'should run and return a Artifact' do
      expect(@buildOperationType).to receive(:new) do |source, version, options|
        expect(source).to equal(@source)
        expect(version).to eq(version)
        expect(options[:connect_to_ec2]).not_to be_nil
        expect(options[:remote_build_config]).not_to be_nil
        @build_operation
      end
      expect(@build_operation).to receive(:run).and_return(@source)
      expect(subject.build('source', 'version')).to eq(@source)
    end

    it 'should raise an error if the Build operation does' do
      expect(@buildOperationType).to receive(:new).and_return(@build_operation)
      expect(@build_operation).to receive(:run).and_raise(ArgumentError.new('something went wrong'))
      expect{ subject.build('source', 'version') }.to raise_error(ArgumentError)
    end

    it 'should call fetch and revparse and use revparsed version in BuildOperation' do
      expect(@source).to receive(:fetch)
      expect(@source).to receive(:revparse).with('version').and_return('abcdef123456')
      expect(@buildOperationType).to receive(:new) do |source, version|
        expect(version).to eq('abcdef123456')
        @build_operation
      end
      subject.build('source', 'version')
    end

    it 'should not build if the artifact is already valid' do
      expect(@buildOperationType).not_to receive(:new)
      expect_any_instance_of(@artifactType).to receive(:valid?).and_return(true)
      expect(subject.build('source', 'version')).to be_a(@artifactType)
    end
  end

  describe 'publish' do
    before(:each) do
      @publishOperationType = Struct.new(:artifact, :environment) do
        def run; self end
      end
      stub_const('Operations::Publish', @publishOperationType)

      @s3Bucket = double()
      @artifact = double(source: 'foo', sha: '12345', s3_bucket: @s3Bucket)
      @runner = OpenStruct.new
      @pipelineRunner = PipelineCommandRunner.new(@runner)
      allow(@pipelineRunner).to receive(:build).and_return(@artifact)
    end

    subject { @pipelineRunner }

    it 'should call build' do
      expect(subject).to receive(:build).with('foo', '12345')
      subject.publish('foo', '12345', 'production')
    end

    it 'should call Operations::Publish' do
      expect(@publishOperationType).to receive(:new).with(@artifact, 'production').and_return(double(run: nil))
      subject.publish('source', '', 'production')
    end
  end

  describe 'deploy' do
    subject {
      ret = PipelineCommandRunner.new(double())
      allow(ret).to receive(:publish).and_return(nil)
      allow(ret).to receive(:restart).and_return(nil)
      ret
    }

    it 'should call publish' do
      expect(subject).to receive(:publish).with('source', 'version', 'production').and_return(nil)
      subject.deploy('source', 'version', 'production/web')
    end

    it 'should restart' do
      expect(subject).to receive(:restart).with('production/web')
      subject.deploy('source', 'version', 'production/web')
    end
  end
end
