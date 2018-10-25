class Ranguba::Template
  def initialize(encodings=nil)
    @encodings = encodings || default_encodings
    @base = Ranguba::Application.config.customize_base_path + 'templates'
    @title_path = @base + 'title.txt'
    @header_path = @base + 'header.txt'
    @footer_path = @base + 'footer.txt'
  end

  def title
    @title ||=
      Ranguba::FileReader.read(@title_path, @encodings['title.txt']) ||
      "Ranguba"
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
end
