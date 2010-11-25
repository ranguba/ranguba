class Ranguba::Template
  def initialize
    @base = Ranguba::Application.config.customize_base_path + 'templates'
    @title_path = @base + 'title.txt'
    @header_path = @base + 'header.txt'
    @footer_path = @base + 'footer.txt'
  end

  def title
    @title ||= File.read(@title_path)
  end

  def header
    @header ||= File.read(@header_path)
  end

  def footer
    @footer ||= File.read(@footer_path)
  end
end
