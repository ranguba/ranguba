require 'csv'

class Ranguba::EncodingLoader

  def initialize
    @base = Ranguba::Application.config.customize_base_path
    @path = @base + 'encodings.csv'
  end

  def load
    encodings = Hash.new {|h, k| h[k] = Encoding::UTF_8}
    return encodings unless File.exist?(@path)
    CSV.foreach(@path, encoding: "utf-8", skip_blanks: true) do |row|
      filename, encoding = row
      encodings[filename] = Encoding.find(encoding)
    end
    encodings
  end
end
