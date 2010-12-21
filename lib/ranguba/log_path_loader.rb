class Ranguba::LogPathLoader
  def initialize
    @base = Ranguba::Application.config.customize_base_path
    @path = File.join(@base, 'log_path.txt')
  end

  def load
    return nil unless File.exist?(@path)
    directory_name = File.readlines(@path).first.chomp
    return nil if directory_name.blank?
    path = Pathname.new(directory_name)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    raise "#{path} is not directory" unless File.directory?(path)
    path
  end
end
