require 'test_helper'

class Ranguba::EncodingLoaderTest < ActiveSupport::TestCase

  def setup
    @loader = Ranguba::EncodingLoader.new
  end

  def test_load
    hash = @loader.load
    assert_equal(hash['categories.csv'], Encoding.find('UTF-8'))
    assert_equal(hash['title.txt'], Encoding.find('UTF-8'))
    assert_equal(hash['header.txt'], Encoding.find('EUC-JP'))
    assert_equal(hash['footer.txt'], Encoding.find('Shift_JIS'))
    assert_equal(hash['unknown.txt'], Encoding.find('UTF-8'))
  end

  def test_load_not_exist_path
    @loader.instance_variable_set(:@path, 'missing')
    hash = @loader.load
    assert_true(hash.empty?)
    assert_equal(hash['categories.csv'], Encoding.find('utf-8'))
  end

end
