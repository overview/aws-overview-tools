require 'pipeline_command_runner'

require 'ostruct'

RSpec.describe PipelineCommandRunner do
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
