# coding: utf-8
require 'test_helper'

class CustomizerTest < ActiveSupport::TestCase
  def setup
    I18n.locale = :ja
  end

  def teardown
    I18n.locale = nil
  end

  def test_title
    assert_equal "ラングバ", Ranguba::Customize.title
    I18n.locale = :en
    assert_equal "Ranguba", Ranguba::Customize.title
  end

  def test_content_header
    assert_equal "<div class=\"header\"></div>\n\n", Ranguba::Customize.content_header
    I18n.locale = :en
    assert_equal "", Ranguba::Customize.content_header
  end

  def test_content_footer
    assert_equal "<div class=\"footer\"></div>\n\n", Ranguba::Customize.content_footer
    I18n.locale = :en
    assert_equal "", Ranguba::Customize.content_footer
  end

  def test_type
    assert_equal "HTML", Ranguba::Customize.type("html")
    I18n.locale = :en
    assert_equal "html", Ranguba::Customize.type("html")
  end

  def test_category
    assert_equal "カテゴリ1", Ranguba::Customize.category("category1")
    I18n.locale = :en
    assert_equal "category1", Ranguba::Customize.category("category1")
  end

  def test_get
    assert_equal "HTML", Ranguba::Customize.get(:type, "html")
    assert_equal "カテゴリ1", Ranguba::Customize.get(:category, "category1")
    I18n.locale = :en
    assert_equal "html", Ranguba::Customize.get(:type, "html")
    assert_equal "category1", Ranguba::Customize.get(:category, "category1")
  end

  def test_category_for_url
    assert_equal "GNU", Ranguba::Customize.category_for_url("http://www.gnu.org/index.html")
    assert_equal "GNU", Ranguba::Customize.category_for_url("http://www.gnu.org/unknown/index.html")
    assert_equal "GNU", Ranguba::Customize.category_for_url("http://www.gnu.org/licenses.html")
    assert_equal "licenses", Ranguba::Customize.category_for_url("http://www.gnu.org/licenses/index.html")
    assert_equal "unknown", Ranguba::Customize.category_for_url("http://www.example.com/")
    assert_equal "unknown", Ranguba::Customize.category_for_url("")
  end

  def test_format_type
    assert_equal "html", Ranguba::Customize.normalize_type("text/html")
    assert_equal "html", Ranguba::Customize.normalize_type("text/html; charset=Shift_JIS")
    assert_equal "html", Ranguba::Customize.normalize_type("application/xhtml+xml")
    assert_equal "css", Ranguba::Customize.normalize_type("text/css")
    assert_equal "aaaaa", Ranguba::Customize.normalize_type("aaaaa")
    assert_equal "unknown", Ranguba::Customize.normalize_type("")
  end
end
