class Ranguba::File

  def self.read(path, external_encoding = Encoding.find('utf-8'))
    return '' unless File.exist?(path)
    if external_encoding == Encoding.find('utf-8')
      File.open(path, "r:utf-8"){|file| file.read }
    else
      File.open(path, "r:#{external_encoding}:utf-8"){|file| file.read }
    end
  end

end
