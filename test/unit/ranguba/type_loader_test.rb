require 'test_helper'

class Ranguba::TypeLoaderTest < ActiveSupport::TestCase

  def setup
    @loader = Ranguba::TypeLoader.new
  end

  def test_load
    result = @loader.load
    expected = [
                %w[text/html html],
                %w[application/xhtml+xml html],
                %w[text/plain plain],
                %w[application/pdf pdf],
                %w[application/vnd.ms-excel excel],
                %w[application/ms-powerpoint powerpoint],
                %w[application/msword word]
               ]
    assert_equal expected, result
  end

  def test_load_labels
    @loader.load_labels
    assert_equal 'HTML', I18n.t('html', :scope => :type)
    assert_equal 'plaintext', I18n.t('plain', :scope => :type)
    assert_equal 'PDF', I18n.t('pdf', :scope => :type)
    assert_equal 'Excel', I18n.t('excel', :scope => :type)
    assert_equal 'PowerPoint', I18n.t('powerpoint', :scope => :type)
    assert_equal 'Word', I18n.t('word', :scope => :type)
  end
end
