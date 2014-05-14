require 'machine_shell'
require 'remote_builder'
require 'source'

require 'aws/ec2'
require 'base64'
require 'net/ssh'

RSpec.describe RemoteBuilder do
  before(:each) do
    @ec2_instances = instance_double('AWS::EC2::InstanceCollection')
    @ec2_volumes = instance_double('AWS::EC2::VolumeCollection')
    @ec2 = instance_double('AWS::EC2')
    @volume = instance_double('AWS::EC2::Volume')
    @attachment = instance_double('AWS::EC2::Attachment')
    allow(@ec2).to receive(:instances).and_return(@ec2_instances)
    allow(@ec2).to receive(:volumes).and_return(@ec2_volumes)
    allow(@ec2_volumes).to receive(:[]).and_return(@volume)
    allow(@volume).to receive(:attach_to).and_return(@attachment)
    allow(@attachment).to receive(:status).and_return(:attached)
  end

  before(:each) do
    @machine_shell = instance_double('MachineShell')
    @machineShellClass = class_double('MachineShell')
    stub_const('MachineShell', @machineShellClass)
    allow(@machineShellClass).to receive(:new).and_return(@machine_shell)
    allow(@machine_shell).to receive(:exec).and_return(true)
  end

  before(:each) do
    @ssh = instance_double('Net::SSH::Connection::Session')
    @netSshModule = double()
    allow(@netSshModule).to receive(:start).and_yield(@ssh)
    stub_const('Net::SSH', @netSshModule)
  end

  subject do
    ret = RemoteBuilder.new(
      @ec2,
      availability_zone: 'us-east-1a',
      security_group: 'build',
      instance_type: 'c3.large',
      ami_id: 'ami-34b5535c',
      cache_volume_id: 'vol-998c9fdb',
      keypair_name: 'manage',
      pause_duration: 0
    )
    allow(ret).to receive(:can_connect_on_port_22?).and_return(true)
    ret
  end

  it('delete this arg https://github.com/rspec/rspec-mocks/issues/619'){ expect(subject.ec2).to equal(@ec2) }
  it('delete this arg https://github.com/rspec/rspec-mocks/issues/619'){ expect(subject.availability_zone).to eq('us-east-1a') }
  it('delete this arg https://github.com/rspec/rspec-mocks/issues/619'){ expect(subject.security_group).to eq('build') }
  it('delete this arg https://github.com/rspec/rspec-mocks/issues/619'){ expect(subject.instance_type).to eq('c3.large') }
  it('delete this arg https://github.com/rspec/rspec-mocks/issues/619'){ expect(subject.ami_id).to eq('ami-34b5535c') }
  it('delete this arg https://github.com/rspec/rspec-mocks/issues/619'){ expect(subject.cache_volume_id).to eq('vol-998c9fdb') }
  it('delete this arg https://github.com/rspec/rspec-mocks/issues/619'){ expect(subject.keypair_name).to eq('manage') }

  describe 'with_instance' do
    it 'should spin up an EC2 instance on start' do
      instance = double(terminate: {}, status: :running, private_ip_address: '10.1.2.3')
      expect(@ec2_instances).to receive(:create).with(
        image_id: 'ami-34b5535c',
        security_groups: 'build',
        availability_zone: 'us-east-1a',
        instance_type: 'c3.large',
        instance_initiated_shutdown_behavior: 'terminate',
        key_name: 'manage',
        block_device_mappings: [{
          device_name: '/dev/sde',
          virtual_name: 'ephemeral0'
        },
        {
          device_name: '/dev/sdf',
          virtual_name: 'ephemeral1'
        }]
      ).and_return(instance)
      subject.with_instance do |x, y|
        expect(x).to equal(instance)
      end
    end

    it 'should spin down an EC2 instance on finish' do
      instance = double(private_ip_address: '10.1.2.3', status: :running)
      expect(@ec2_instances).to receive(:create).and_return(instance)
      expect(instance).to receive(:terminate)
      subject.with_instance {}
    end

    it 'should not yield until the instance has an IP address' do
      instance = double(terminate: {}, status: :running)
      expect(@ec2_instances).to receive(:create).and_return(instance)
      expect(instance).to receive(:private_ip_address).and_return(nil, nil, '10.1.2.3', '10.1.2.3', '10.1.2.3', '10.1.2.3')
      subject.with_instance do |x, y|
        expect(x.private_ip_address).to eq('10.1.2.3')
      end
    end

    it 'should wait for the instance to listen on port 22' do
      instance = double(terminate: {}, private_ip_address: '10.1.2.3', status: :running)
      expect(@ec2_instances).to receive(:create).and_return(instance)
      expect(subject).to receive(:can_connect_on_port_22?).with('10.1.2.3').and_return(false, false, true, true)
      subject.with_instance do |x, y|
        expect(subject.send(:can_connect_on_port_22?, '10.1.2.3')).to be(true)
      end
    end

    it 'should start an SSH session' do
      shell = double()
      allow(shell).to receive(:exec).and_return(true)
      instance = double(terminate: {}, private_ip_address: '10.1.2.3', status: :running)
      expect(@ec2_instances).to receive(:create).and_return(instance)
      expect(subject).to receive(:with_machine_shell).with('10.1.2.3').and_yield(shell)
      subject.with_instance do |x, y|
        expect(y).to equal(shell)
      end
    end
  end

  describe 'build' do
    before(:each) do
      @archive = Tempfile.new('overview-manage-remote-builder-spec')
      # A tarball containing "foo/bar.txt" with contents "baz"
      #
      # This is mock source code, as produced from "git archive"
      @archive.write(Base64.decode64(%{
        H4sIABAFaFMAA+3RPQrCQBCG4ak9xZ5A93/Os0HSSSCuIJ7ebCEEiwSERcT3aaaYgfngG6fpJJ3Z
        hWpq02my6/kizofgVGO2KtZZH4OY1DtYc7vWMhsj5VwuW3d7+x81Lv0PZT7We+32oxWcc9zoP771
        71L0Ymy3RCt/3v9QHodvZwAAAAAAAAAAAAAAAADwmScFkK8tACgAAA==
      }))
      @archive.rewind

      @instance = instance_double('AWS::EC2::Instance')
      @machine_shell = instance_double('MachineShell')
      allow(subject).to receive(:with_instance).and_yield(@instance, @machine_shell)
      allow(@machine_shell).to receive(:upload_r).and_return(true)
      allow(@machine_shell).to receive(:download).and_return(true)
      allow(@machine_shell).to receive(:exec).and_return(true)
      allow(@machine_shell).to receive(:mkdir_p).and_return(true)
      allow(@machine_shell).to receive(:md5sum).and_return('abcdef123456abcdef123456abcdef12')
    end

    after(:each) do
      @archive.close!
    end

    it 'should spin up and shut down an instance' do
      expect(subject).to receive(:with_instance)
      subject.build(@archive.path, [ 'echo foo' ], '/output/path')
    end

    it 'should copy the build file in, unzip it, and cd into it' do
      expect(@machine_shell).to receive(:exec).with('cd build && tar zxf ../archive.tar.gz').and_return(true)
      subject.build(@archive.path, [ 'echo foo' ], '/output/path')
    end

    it 'should run build commands' do
      expect(@machine_shell).to receive(:exec).with('cd build && echo foo').and_return(true)
      subject.build(@archive.path, [ 'echo foo' ], '/output/path')
    end

    it 'should copy the archive file out' do
      expect(@machine_shell).to receive(:download).with('build/archive.zip', '/output/path')
      subject.build(@archive_path, [], '/output/path')
    end

    it 'should return the md5' do
      expect(@machine_shell).to receive(:md5sum).with('build/archive.zip').and_return('abcdef12345')
      expect(subject.build(@archive_path, [], '/output/path')).to eq('abcdef12345')
    end
  end
end
