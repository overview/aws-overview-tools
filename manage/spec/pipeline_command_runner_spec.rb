require 'pipeline_command_runner'

require 'ostruct'

RSpec.describe PipelineCommandRunner do
  describe 'build' do
    before(:each) do
      @buildOperationType = Struct.new(:source, :treeish)
      stub_const('Operations::Build', @buildOperationType)

      @sourceArtifactType = Struct.new(:source, :sha)
      stub_const('SourceArtifact', @sourceArtifactType)
      allow_any_instance_of(@sourceArtifactType).to receive(:valid?).and_return(false)

      @source = double()
      allow(@source).to receive(:fetch)
      allow(@source).to receive(:revparse).with('version').and_return('version')

      @runner = OpenStruct.new
      @runner.sources = { 'source' => @source }
    end

    subject { PipelineCommandRunner.new(@runner) }

    it 'should run and return a SourceArtifact' do
      expect(@buildOperationType).to receive(:new).with(@source, 'version').and_call_original
      expect_any_instance_of(@buildOperationType).to receive(:run).and_return(@source)
      expect(subject.build('source', 'version')).to eq(@source)
    end

    it 'should raise an error if the source is not found' do
      expect{ subject.build('invalid-source', 'version')}.to raise_error(RuntimeError)
    end

    it 'should raise an error if the Build operation does' do
      expect(@buildOperationType).to receive(:new).with(@source, 'version').and_call_original
      expect_any_instance_of(@buildOperationType).to receive(:run).and_raise(ArgumentError.new('something went wrong'))
      expect{ subject.build('source', 'version') }.to raise_error(ArgumentError)
    end

    it 'should call fetch and revparse and use revparsed version in BuildOperation' do
      expect(@buildOperationType).to receive(:new).with(@source, 'abcdef123456').and_call_original
      allow_any_instance_of(@buildOperationType).to receive(:run).and_return(@source)
      expect(@source).to receive(:fetch)
      expect(@source).to receive(:revparse).with('version').and_return('abcdef123456')
      subject.build('source', 'version')
    end

    it 'should not build if the source artifact is already valid' do
      expect(@buildOperationType).not_to receive(:new)
      expect_any_instance_of(@sourceArtifactType).to receive(:valid?).and_return(true)
      expect(subject.build('source', 'version')).to be_a(@sourceArtifactType)
    end
  end

  describe 'prepare' do
    before(:each) do
      @source_artifact = double()

      @prepareOperationType = Struct.new(:source_artifact, :component, :environment) do
        def run; self end
      end
      stub_const('Operations::Prepare', @prepareOperationType)

      @runner = double()
      allow(@runner).to receive(:components_with_source).and_return([])
    end

    subject {
      ret = PipelineCommandRunner.new(@runner)
      allow(ret).to receive(:build).and_return(@source_artifact)
      ret
    }

    it 'should call build() to get a SourceArtifact' do
      expect(subject).to receive(:build).with('source', 'version').and_return(@source_artifact)
      subject.prepare('source', 'version', 'environment')
    end

    it 'should call runner.components_with_source() to find Components' do
      expect(@runner).to receive(:components_with_source).with('source').and_return([])
      subject.prepare('source', 'version', 'environment')
    end

    it 'should run Operations::Prepare once per Component' do
      allow(@runner).to receive(:components_with_source).with('source').and_return([ 'MockComponentA', 'MockComponentB' ])
      component = double()
      allow(@prepareOperationType).to receive(:new).with(@source_artifact, 'MockComponentA', 'environment').and_return(component)
      allow(@prepareOperationType).to receive(:new).with(@source_artifact, 'MockComponentB', 'environment').and_return(component)
      expect(component).to receive(:run).twice
      subject.prepare('source', 'version', 'environment')
    end

    it 'should return an Array of ComponentArtifacts' do
      allow(@runner).to receive(:components_with_source).with('source').and_return([ 'MockComponentA', 'MockComponentB' ])
      allow_any_instance_of(@prepareOperationType).to receive(:run).and_return('ComponentArtifact')
      expect(subject.prepare('source', 'version', 'environment')).to eq([ 'ComponentArtifact', 'ComponentArtifact' ])
    end
  end

  describe 'publish' do
    before(:each) do
      @publishOperationType = Struct.new(:component_artifact, :machine) do
        def run; self end
      end
      stub_const('Operations::Publish', @publishOperationType)

      @runner = OpenStruct.new
      allow(@runner).to receive(:machines_with_spec).and_return([
        double(components: Set.new(), environment: 'production'),
        double(components: Set.new(), environment: 'production')
      ])
    end

    subject {
      ret = PipelineCommandRunner.new(@runner)
      allow(ret).to receive(:prepare).and_return([])
      ret
    }

    it 'should fetch machines from runner' do
      machine = double(environment: 'production', components: Set.new())
      expect(@runner).to receive(:machines_with_spec).with('production.web').and_return([machine])
      subject.publish('source', 'version', 'production.web')
    end

    it 'should throw an ArgumentError if there are no machines' do
      allow(@runner).to receive(:machines_with_spec).and_return([])
      expect{ subject.publish('source', 'version', 'production.web') }.to raise_error(ArgumentError)
    end

    it 'should fetch component artifacts by preparing in the environment' do
      allow(@runner).to receive(:machines_with_spec).and_return([ double(components: Set.new(), environment: 'production') ])
      expect(subject).to receive(:prepare).with('source', 'version', 'production').and_return([ double(component: 'a-component') ])
      subject.publish('source', 'version', 'production.web')
    end

    it 'should call Operations::Publish for every component+machine duo' do
      component_artifact1 = double('component_artifact1', component: 'component1')
      component_artifact2 = double('component_artifact2', component: 'component2')
      machine1 = double('machine1', environment: 'production', components: Set.new([ 'component1', 'component2' ]))
      machine2 = double('machine2', environment: 'production', components: Set.new([ 'component1' ]))

      allow(subject).to receive(:prepare).and_return([ component_artifact1, component_artifact2 ])
      allow(@runner).to receive(:machines_with_spec).and_return([ machine1, machine2 ])

      expect(@publishOperationType).to receive(:new).with(component_artifact1, machine1).and_return(double(run: nil))
      expect(@publishOperationType).to receive(:new).with(component_artifact1, machine2).and_return(double(run: nil))
      expect(@publishOperationType).to receive(:new).with(component_artifact2, machine1).and_return(double(run: nil))
      expect(@publishOperationType).not_to receive(:new).with(component_artifact2, machine2)

      expect(subject.publish('source', 'version', 'production.web')).to eq([
        [ component_artifact1, machine1 ],
        [ component_artifact1, machine2 ],
        [ component_artifact2, machine1 ]
      ])
    end
  end

  describe 'install' do
    before(:each) do
      @installOperationType = Struct.new(:component_artifact, :machine) do
        def run; nil end
      end
      stub_const('Operations::Install', @installOperationType)
    end

    subject { PipelineCommandRunner.new(@runner) }

    it 'should call publish and return the same values' do
      component1 = double()
      component2 = double()
      machine1 = double()
      machine2 = double()

      publish_retval = [
        [ component1, machine1 ],
        [ component2, machine2 ]
      ]

      expect(subject).to receive(:publish).with('source', 'version', 'machines').and_return(publish_retval)
      expect(subject.publish('source', 'version', 'machines')).to equal(publish_retval)
    end

    it 'should run Operations::Install on each pair' do
      artifact1 = double('artifact1')
      artifact2 = double('artifact2')
      machine1 = double('machine1')

      allow(subject).to receive(:publish).and_return([[ artifact1, machine1 ], [ artifact2, machine1 ]])
      oneInstallOperation = double(run: nil)
      expect(oneInstallOperation).to receive(:run).and_return(nil)
      expect(@installOperationType).to receive(:new).with(artifact1, machine1).and_return(oneInstallOperation)
      expect(@installOperationType).to receive(:new).with(artifact2, machine1).and_return(double(run: nil))

      subject.install('source', 'version', 'machines')
    end
  end

  describe 'deploy' do
    before(:each) do
      @deployOperationType = Struct.new(:component, :machine) do
        def run; nil end
      end
      stub_const('Operations::Deploy', @deployOperationType)

      @runner = OpenStruct.new
      @runner.components = {
        'componentA' => 'MockComponentA',
        'componentB' => 'MockComponentB'
      }
    end

    subject { PipelineCommandRunner.new(@runner) }

    it 'should call install' do
      install_retval = [
        [ double(component: 'componentA'), double() ],
        [ double(component: 'componentB'), double() ]
      ]
      expect(subject).to receive(:install).with('source', 'version', 'machines').and_return(install_retval)
      expect(subject.deploy('source', 'version', 'machines')).to equal(install_retval)
    end

    it 'should run Operations::Deploy on each (Component, Machine) pair' do
      artifact1 = double('artifact1', component: 'componentA')
      artifact2 = double('artifact2', component: 'componentB')
      machine1 = double('machine1')
      machine2 = double('machine2')

      install_retval = [
        [ artifact1, machine1 ],
        [ artifact2, machine1 ],
        [ artifact1, machine2 ]
      ]

      allow(subject).to receive(:install).and_return(install_retval)

      oneDeployOperation = double(run: nil)
      expect(oneDeployOperation).to receive(:run).and_return(nil)

      expect(@deployOperationType).to receive(:new).with('MockComponentA', machine1).and_return(oneDeployOperation)
      expect(@deployOperationType).to receive(:new).with('MockComponentB', machine1).and_return(double(run: nil))
      expect(@deployOperationType).to receive(:new).with('MockComponentA', machine2).and_return(double(run: nil))

      subject.deploy('source', 'version', 'machines')
    end
  end
end
