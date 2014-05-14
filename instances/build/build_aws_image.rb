#!/usr/bin/env ruby

require_relative '../common/aws_image'

class BuildAwsImage < AwsImage
  def packages
    super + %W(
      build-essential
      nodejs
      nodejs-dev
      npm
      openjdk-7-jdk
      zip
    )
  end

  def self.type_tag
    'build'
  end

  def run_ssh_commands(ssh)
    super(ssh)

    build_commands = [
      'sudo update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10'
    ]

    ssh.exec("(#{build_commands.join(' && ')})")
  end
end
