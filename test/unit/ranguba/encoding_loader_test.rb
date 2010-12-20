require 'test_helper'

class Ranguba::EncodingLoaderTest < ActiveSupport::TestCase

  def setup
    @loader = Ranguba::EncodingLoader.new
  end

  def test_load
    hash = @loader.load
    assert_equal(Encoding.find('UTF-8'), hash['categories.csv'])
    assert_equal(Encoding.find('utf-8'), hash['title.txt'])
    assert_equal(Encoding.find('utf-8'), hash['header.txt'])
    assert_equal(Encoding.find('utf-8'), hash['footer.txt'])
    assert_equal(Encoding.find('utf-8'), hash['unknown.txt'])
  end

  def test_load_not_exist_path
    @loader.instance_variable_set(:@path, 'missing')
    hash = @loader.load
    assert_true(hash.empty?)
    assert_equal(Encoding.find('utf-8'), hash['categories.csv'])
  end

end
