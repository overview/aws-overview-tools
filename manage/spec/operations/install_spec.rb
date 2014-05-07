require 'operations/install'

RSpec.describe Operations::Install do
  before(:each) do
    @component_artifact = double('ComponentArtifact', component: 'component', files_path: '/tmp/files', install_path: '/tmp/install')
    @machine = double('Machine')
    @shell = double('Shell')
    allow(@machine).to receive(:shell).and_yield(@shell)
  end

  subject { Operations::Install.new(@component_artifact, @machine) }

  it 'should modify the symlink' do
    expect(@machine).to receive(:shell).and_yield(@shell)
    expect(@shell).to receive(:ln_sf).with('/tmp/files', '/tmp/install').and_return(true)
    expect(subject.run).to be(true)
  end
end
