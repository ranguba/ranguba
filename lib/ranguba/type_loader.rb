require 'csv'

class Ranguba::TypeLoader

  def initialize(encoding=Encoding.find("utf-8"))
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
    hash = {}
    Ranguba::FileReader.read_csv(@path, @encoding) do |row|
      _, key, label = row
      hash[key] = label
    end
    # FIXME
    I18n.backend.store_translations('en', :type => hash)
    I18n.backend.store_translations('ja', :type => hash)
    nil
  end
end
