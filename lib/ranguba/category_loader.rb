require 'csv'

class Ranguba::CategoryLoader

  def initialize
    @base = Ranguba::Application.config.customize_base_path
    @path = @base + 'categories.csv'
  end

  def load
    array = []
    CSV.foreach(@path, encoding:"utf-8", skip_blanks:true) do |row|
      url, key, _ = row
      array << [url, key]
    end
    array
  end

  def load_labels
    hash = {}
    CSV.foreach(@path, encoding:"utf-8", skip_blanks:true) do |row|
      _, key, label = row
      hash[key] = label
    end
    # FIXME
    I18n.backend.store_translations('en', :category => hash)
    I18n.backend.store_translations('ja', :category => hash)
    nil
  end
end
