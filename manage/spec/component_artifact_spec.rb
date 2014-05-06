require 'component_artifact'

require 'fileutils'

RSpec.describe ComponentArtifact do
  describe 'with a ComponentArtifact' do
    subject { ComponentArtifact.new('component', 'abcdef123456', 'production') }

    it { expect(subject.path).to eq('/opt/overview/manage/component-artifacts/component/abcdef123456/production') }
    it { expect(subject.files_path).to eq('/opt/overview/manage/component-artifacts/component/abcdef123456/production/files') }
    it { expect(subject.md5sum_path).to eq('/opt/overview/manage/component-artifacts/component/abcdef123456/production/md5sum.txt') }
    it { expect(subject.file_path('foo.txt')).to eq('/opt/overview/manage/component-artifacts/component/abcdef123456/production/files/foo.txt') }
  end

  it 'should allow setting the :root of the path' do
    subject = ComponentArtifact.new('component', 'abcdef123456', 'production', root: '/tmp')
    expect(subject.path).to start_with('/tmp/component')
  end

  describe 'with the filesystem mocked' do
    before(:each) { @tmpdir = Dir.mktmpdir('overview-manage-component-artifact-spec') }
    after(:each) { FileUtils.remove_entry(@tmpdir) }

    subject { ComponentArtifact.new('component', 'abcdef123456', 'production', root: @tmpdir) }

    describe 'with an empty ComponentArtifact' do
      it { expect(subject.files).to be_nil }
      it { expect(subject.valid?).to be(false) }
    end

    describe 'when files are present' do
      before(:each) do
        FileUtils.mkdir_p(subject.files_path)
        open(subject.file_path('foo.txt'), 'wb') { |f| f.write('bar') }
        open(subject.file_path('bar.txt'), 'wb') { |f| f.write('baz') }
        open(subject.md5sum_path, 'wb') { |f| f.write(<<-EOS
          73feffa4b7f6bb68e44cf984c85f6e88 *bar.txt
          37b51d194a7513e45b56f6524f2d51f2 *foo.txt
          EOS
        ) }
      end

      it { expect(subject.valid?).to be(true) }
      it { expect(subject.files.sort).to eq([ 'bar.txt', 'foo.txt' ]) }

      it 'should not be valid if the md5sum is wrong' do
        open(subject.file_path('foo.txt'), 'wb') { |f| f.write("bar\n") }
        expect(subject.valid?).to be(false)
      end

      it 'should not be valid if a file is missing from the checksum' do
        FileUtils.remove_entry(subject.file_path('bar.txt'))
        expect(subject.valid?).to be(false)
      end

      it 'should not be valid if there is an extra file not checksummed' do
        open(subject.file_path('baz.txt'), 'wb') { |f| f.write('foo') }
        expect(subject.valid?).to be(false)
      end
    end
  end
end
