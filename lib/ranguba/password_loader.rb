require 'csv'

class Ranguba::PasswordLoader
  def initialize
    @base = Ranguba::Application.config.customize_base_path
    @path = File.join(@base, 'passwords.csv')
  end

  def load
    records = []
    begin
      CSV.foreach(@path, encoding:"utf-8", skip_blanks:true) do |row|
        url, username, password = row
        url.gsub!(/\/\Z/, '') # remove trailing slash
        records << {:url => url, :username => username, :password => password}
      end
    rescue Errno::ENOENT
    end
    records
  end
end
