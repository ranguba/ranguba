require 'csv'

class Ranguba::TypeLoader

  def initialize
    @base = Ranguba::Application.config.customize_base_path
    @path = @base + 'types.csv'
  end

  def load
    array = []
    CSV.foreach(@path, encoding:'utf-8', skip_blanks:true) do |row|
      mime_type, key, _ = row
      array << [mime_type, key]
    end
    array
  end

  def load_labels
    hash = {}
    CSV.foreach(@path, encoding:'utf-8', skip_blanks:true) do |row|
      _, key, label = row
      hash[key] = label
    end
    # FIXME
    I18n.backend.store_translations('en', :type => hash)
    I18n.backend.store_translations('ja', :type => hash)
    nil
  end
end
