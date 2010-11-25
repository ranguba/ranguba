# -*- coding: utf-8 -*-
require 'test_helper'

class Ranguba::CategoryLoaderTest < ActiveSupport::TestCase
  def setup
    @loader = Ranguba::CategoryLoader.new
  end
  def teardown
  end

  def test_load
    result = @loader.load
    assert_equal [%w[http://www.google.com/ google],
                  %w[http://www.clear-code.com/ public],
                  %w[http://www.clear-code.com/blog/ blog]], result
  end

  def test_load_labels
    @loader.load_labels
    I18n.locale = :en
    assert_equal 'Google', I18n.t(:google, :scope => :category)
    assert_equal '公開'  , I18n.t(:public, :scope => :category)
    assert_equal 'ブログ', I18n.t(:blog, :scope => :category)

    I18n.locale = :ja
    assert_equal('Google', I18n.t(:google, :scope => :category))
    assert_equal('公開', I18n.t(:public, :scope => :category))
    assert_equal('ブログ', I18n.t(:blog, :scope => :category))
  end
end
