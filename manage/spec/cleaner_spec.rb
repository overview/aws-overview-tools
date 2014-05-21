require 'cleaner'
require 'machine_shell'

describe Cleaner do
  before(:each) do
    @shell = instance_double('MachineShell')
  end

  it 'should list artifacts using the shell' do
    expect(@shell).to receive(:component_artifacts_with_timestamps).and_return([])
    subject.clean(:component_artifacts, @shell)
  end

  describe 'with some source artifacts' do
    it 'should clean some old artifacts' do
      expect(@shell).to receive(:source_artifacts_with_timestamps).and_return([
        double(source_artifact: double(source: 'source1', path: '/sources/1/b'), timestamp: Time.at(4)),
        double(source_artifact: double(source: 'source1', path: '/sources/1/a'), timestamp: Time.at(1)),
        double(source_artifact: double(source: 'source1', path: '/sources/1/c'), timestamp: Time.at(3)),
        double(source_artifact: double(source: 'source1', path: '/sources/1/d'), timestamp: Time.at(2))
      ])
      expect(@shell).to receive(:rm_rf).with('/sources/1/a')
      expect(@shell).to receive(:rm_rf).with('/sources/1/d')
      subject.clean(:source_artifacts, @shell, keep: 2)
    end

    it 'should not clean any artifacts when there are not as many as the limit' do
      expect(@shell).to receive(:source_artifacts_with_timestamps).and_return([
        double(source_artifact: double(source: 'source1', path: '/sources/1/b'), timestamp: Time.at(4)),
        double(source_artifact: double(source: 'source1', path: '/sources/1/c'), timestamp: Time.at(3)),
      ])
      expect(@shell).not_to receive(:rm_rf)
      subject.clean(:source_artifacts, @shell, keep: 2)
    end

    it 'should keep n artifacts per source, not total' do
      expect(@shell).to receive(:source_artifacts_with_timestamps).and_return([
        double(source_artifact: double(source: 'source1', path: '/sources/1/b'), timestamp: Time.at(6)),
        double(source_artifact: double(source: 'source1', path: '/sources/1/a'), timestamp: Time.at(1)),
        double(source_artifact: double(source: 'source1', path: '/sources/1/c'), timestamp: Time.at(3)),
        double(source_artifact: double(source: 'source1', path: '/sources/1/d'), timestamp: Time.at(2)),
        double(source_artifact: double(source: 'source2', path: '/sources/2/c'), timestamp: Time.at(7)),
        double(source_artifact: double(source: 'source2', path: '/sources/2/b'), timestamp: Time.at(5)),
        double(source_artifact: double(source: 'source2', path: '/sources/2/a'), timestamp: Time.at(4))
      ])
      expect(@shell).to receive(:rm_rf).with('/sources/1/a')
      expect(@shell).to receive(:rm_rf).with('/sources/1/d')
      expect(@shell).to receive(:rm_rf).with('/sources/2/a')
      subject.clean(:source_artifacts, @shell, keep: 2)
    end
  end

  describe 'with some component artifacts' do
    it 'should clean old artifacts' do
      expect(@shell).to receive(:component_artifacts_with_timestamps).and_return([
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/b', install_path: '/foo'), timestamp: Time.at(4)),
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/a', install_path: '/foo'), timestamp: Time.at(1)),
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/c', install_path: '/foo'), timestamp: Time.at(3)),
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/d', install_path: '/foo'), timestamp: Time.at(2))
      ])
      expect(@shell).to receive(:rm_rf).with('/components/1/a')
      expect(@shell).to receive(:rm_rf).with('/components/1/d')
      allow(@shell).to receive(:readlink).and_return('/asd')
      subject.clean(:component_artifacts, @shell, keep: 2)
    end

    it 'should keep n artifacts per environment, not total' do
      expect(@shell).to receive(:component_artifacts_with_timestamps).and_return([
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/b', install_path: '/foo'), timestamp: Time.at(4)),
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/a', install_path: '/foo'), timestamp: Time.at(1)),
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/c', install_path: '/foo'), timestamp: Time.at(3)),
        double(component_artifact: double(component: 'component1', environment: 'staging', path: '/components/1/d', install_path: '/foo'), timestamp: Time.at(2))
      ])
      expect(@shell).to receive(:rm_rf).with('/components/1/a')
      allow(@shell).to receive(:readlink).and_return('/asd')
      subject.clean(:component_artifacts, @shell, keep: 2)
    end

    it 'should not clean the installed artifact, even when it is old' do
      expect(@shell).to receive(:component_artifacts_with_timestamps).and_return([
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/b', install_path: '/foo'), timestamp: Time.at(4)),
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/a', install_path: '/foo'), timestamp: Time.at(1)),
        double(component_artifact: double(component: 'component1', environment: 'production', path: '/components/1/c', install_path: '/foo'), timestamp: Time.at(3))
      ])
      expect(@shell).to receive(:readlink).with('/foo').and_return('/components/1/a')
      expect(@shell).not_to receive(:rm_rf).with('/components/1/a')
      subject.clean(:component_artifacts, @shell, keep: 2)
    end
  end
end
