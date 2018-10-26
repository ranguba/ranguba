class Ranguba::CategoryLoader

  def initialize(encoding=Encoding::UTF_8)
    @base = Ranguba::Application.config.customize_base_path
    base_path = 'categories.csv'
    @path = @base + base_path
    unless @path.exist?
      @path = @base + "#{base_path}.sample"
    end
    @encoding = encoding
  end

  def load
    array = []
    Ranguba::FileReader.read_csv(@path, @encoding) do |row|
      url, key, _ = row
      array << [url, key]
    end
    array
  end

  def load_labels
    hash = {}
    Ranguba::FileReader.read_csv(@path, @encoding) do |row|
      _, key, label = row
      hash[key] = label
    end
    # FIXME
    I18n.backend.store_translations('en', :category => hash)
    I18n.backend.store_translations('ja', :category => hash)
    nil
  end
end
