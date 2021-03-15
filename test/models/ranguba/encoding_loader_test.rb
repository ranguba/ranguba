require 'test_helper'

class Ranguba::EncodingLoaderTest < ActiveSupport::TestCase

  def setup
    @loader = Ranguba::EncodingLoader.new
  end

  def test_load
    encodings = @loader.load
    expected = {
      'categories.csv' => Encoding::UTF_8,
      'title.txt'      => Encoding::UTF_8,
      'header.txt'     => Encoding::EUC_JP,
      'footer.txt'     => Encoding::Shift_JIS,
    }
    assert_equal(expected, encodings)
    assert_equal(Encoding::UTF_8, encodings['unknown.txt'])
  end

  def test_load_not_exist_path
    @loader.instance_variable_set(:@path, 'missing')
    encodings = @loader.load
    assert_true(encodings.empty?)
    assert_equal(Encoding::UTF_8, encodings['categories.csv'])
  end

end
