require 'find'
require 'set'

require_relative 'log'

class ComponentArtifact
  attr_reader(:component, :sha, :environment)

  def initialize(component, sha, environment, options = {})
    @component = component
    @sha = sha
    @environment = environment
    @options = options
  end

  def path
    root = @options[:root] || '/opt/overview/manage/component-artifacts'
    "#{root}/#{component}/#{sha}/#{environment}"
  end

  def to_s; path end

  def install_path
    "/opt/overview/#{component}"
  end

  def files_path
    "#{path}/files"
  end

  def file_path(relative_path)
    "#{files_path}/#{relative_path}"
  end

  def md5sum_path
    "#{path}/md5sum.txt"
  end

  def files
    return nil if !File.exist?(files_path)

    enum_files.to_a
  end

  def valid?
    $log.info('component-artifact') { "Validating #{to_s}" }
    File.exist?(md5sum_path) && all_files_in_md5sum? && all_md5sum_files_valid?
  end

  private

  def enum_files
    Enumerator.new do |y|
      Dir.chdir(files_path) do
        Find.find(files_path) do |path|
          if !FileTest.directory?(path)
            relative_path = path[files_path.length + 1..-1]
            y << relative_path
          end
        end
      end
    end
  end

  def all_md5sum_files_valid?
    Dir.chdir(files_path) do
      system(%{md5sum -c --status "#{md5sum_path}"})
    end
  end

  def all_files_in_md5sum?
    regex = /[0-9a-f]{32} [ \*](.*)$/

    files_in_md5sum = IO.readlines(md5sum_path)
      .map{ |l| regex.match(l) }
      .compact
      .map{ |m| m[1] }

    files_on_fs = files

    Set.new(files_on_fs) == Set.new(files_in_md5sum)
  end
end
