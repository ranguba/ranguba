require 'csv'

class Ranguba::EncodingLoader

  def initialize
    @base = Ranguba::Application.config.customize_base_path
    @path = @base + 'encodings.csv'
  end

  def load
    hash = Hash.new{|h,k| h[k] = Encoding.find("utf-8")}
    return hash unless File.exist?(@path)
    CSV.foreach(@path, encoding:"utf-8", skip_blanks:true) do |row|
      filename, encoding = row
      hash[filename] = Encoding.find(encoding)
    end
    hash
  end
end
