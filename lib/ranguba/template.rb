class Ranguba::Template
  def initialize(encodings=nil)
    @encodings = encodings || default_encodings
    @base = Ranguba::Application.config.customize_base_path + 'templates'
    @title_path = build_path('title.txt')
    @header_path = build_path('header.txt')
    @footer_path = build_path('footer.txt')
  end

  def title
    @title ||= Ranguba::FileReader.read(@title_path, @encodings['title.txt'])
  end

  def header
    @header ||= Ranguba::FileReader.read(@header_path, @encodings['header.txt'])
  end

  def footer
    @footer ||= Ranguba::FileReader.read(@footer_path, @encodings['footer.txt'])
  end

  private
  def default_encodings
    {
      'title.txt'  => Encoding::UTF_8,
      'header.txt' => Encoding::UTF_8,
      'footer.txt' => Encoding::UTF_8,
    }
  end

  def build_path(path)
    full_path = @base + path
    return full_path if full_path.exist?
    @base + "#{path}.sample"
  end
end
