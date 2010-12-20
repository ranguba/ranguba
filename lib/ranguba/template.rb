class Ranguba::Template
  def initialize(encodings = {
                   'title.txt'  => Encoding.find('utf-8'),
                   'header.txt' => Encoding.find('utf-8'),
                   'footer.txt' => Encoding.find('utf-8'),
                 })
    @encodings = encodings
    @base = Ranguba::Application.config.customize_base_path + 'templates'
    @title_path = @base + 'title.txt'
    @header_path = @base + 'header.txt'
    @footer_path = @base + 'footer.txt'
  end

  def title
    @title ||= read(@title_path, @encodings['title.txt'])
  end

  def header
    @header ||= read(@header_path, @encodings['header.txt'])
  end

  def footer
    @footer ||= read(@footer_path, @encodings['footer.txt'])
  end

  def read(path, encoding=Encoding.find('utf-8'))
    return '' unless File.exist?(path)
    File.open(path, "r:#{encoding}"){|file| file.read }
  end
end
