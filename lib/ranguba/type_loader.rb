class Ranguba::TypeLoader

  def initialize(encoding=Encoding::UTF_8)
    @base = Ranguba::Application.config.customize_base_path
    @path = @base + 'types.csv'
    @encoding = encoding
  end

  def load
    array = []
    Ranguba::FileReader.read_csv(@path, @encoding) do |row|
      mime_type, key, _ = row
      array << [mime_type, key]
    end
    array
  end

  def load_labels
    [nil, "en", "ja"].each do |language|
      labels = {}
      if language.nil?
        path = @base + "types.csv"
      else
        path = @base + "types.#{language}.csv"
      end
      next unless path.exist?
      Ranguba::FileReader.read_csv(path, @encoding) do |row|
        _, key, label = row
        labels[key] = label
      end
      I18n.backend.store_translations(language || 'en', :type => labels)
    end
    nil
  end
end
