
require 'optparse'
require 'erb'
require 'fileutils'

class InstallerGenerator
  def initialize(argv)
    @base_dir = File.expand_path(File.dirname(__FILE__))
    @user = 'ranguba'
    @prefix = '$(getent passwd |grep ${RANGUBA_USERNAME}| cut -d : -f 6)'
    @httpd_prefix = '/usr/local/apache2'
    @document_root = '$HTTPD_PREFIX/htdocs'
    @output_dir = File.join(@base_dir, 'ranguba_installer')
    @ranguba_archive_name = 'ranguba.tar.gz'
    parser = OptionParser.new(argv)
    parser.banner = "#{$0} OPTIONS"
    parser.on('-u', '--user=USER') do |v|
      @user = v
    end
    parser.on('-p', '--prefix=PREFIX') do |v|
      @prefix = v
    end
    parser.on('-a', '--httpd-prefix=HTTPD_PREFIX') do |v|
      @httpd_prefix = v
    end
    parser.on('-d', '--document-root=DOCUMENT_ROOT') do |v|
      @document_root = v
    end
    parser.on('-o', '--output-dir=OUTPUT_DIR') do |v|
      @output_dir = File.expand_path(v)
    end
    parser.on('-n', '--archive-name=ARCHIVE_NAME') do |v|
      @ranguba_archive_name = v
    end
    begin
      parser.parse!
    rescue OptionParser::ParseError => ex
      $stderr.puts ex.message
      exit 1
    end
    @source_dir = File.join(@output_dir, 'sources')
  end

  def generate
    erb = ERB.new(File.read('templates/install.sh.erb'), nil, '-')
    FileUtils.mkdir_p(@output_dir)
    File.open(File.join(@output_dir, 'install.sh'), 'w+:utf-8') do |file|
      file.write(erb.result(binding))
    end
  end

  def package
    FileUtils.mkdir_p @source_dir
    prepare_gems
    ENV['SOURCE'] = @source_dir
    ENV['nocheck'] = 'yes'
    ENV['noinst'] = 'yes'
    `./install_sources_and_gems.sh`
    FileUtils.cp(['install_sources_and_gems.sh', 'sourcelist'], @output_dir)
    FileUtils.mkdir_p(File.join(@output_dir, 'data'))
    FileUtils.cp(Dir.glob('./data/*').to_a, File.join(@output_dir, 'data'))
    Dir.chdir('../') do
      `git archive --format=tar --prefix=ranguba/ HEAD | gzip > ./ranguba.tar.gz`
      FileUtils.mv('ranguba.tar.gz', @source_dir)
    end
    files = check_filesize
    if files.empty?
      puts 'done'
    else
      files.each{|v| warn "#{v} is empty." }
    end
  end

  private

  def prepare_gems
    print 'Prepare gems...'
    Dir.chdir('../') do
      `bundle package`
      FileUtils.cp(Dir.glob('vendor/cache/*.gem').to_a, "#{@source_dir}/")
    end
    puts 'done'
  end

  def check_filesize
    Dir.glob(@source_dir).select do |entry|
      File.size(entry) == 0
    end
  end
end

def main
  g = InstallerGenerator.new(ARGV)
  g.generate
  g.package
end

if $0 == __FILE__
  main
end
