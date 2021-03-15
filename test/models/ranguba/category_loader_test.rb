# -*- coding: utf-8 -*-
require 'test_helper'

class Ranguba::CategoryLoaderTest < ActiveSupport::TestCase
  def setup
    @loader = Ranguba::CategoryLoader.new
  end
  def teardown
    I18n.locale = :en
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

  def test_load_with_sjis
    @loader = Ranguba::CategoryLoader.new(Encoding::Shift_JIS)
    path = Rails.root + 'tmp' + 'categories.csv'
    File.open(path, 'w+:sjis:utf-8') do |file|
      str=<<CSV
http://www.example.com/,public,オフィシャルサイト
http://www.example.com/test,test,テストサイト
CSV
      file.sync = true
      file.puts str
      @loader.instance_variable_set(:@base, Rails.root + 'tmp')
      @loader.instance_variable_set(:@path, file.path)
      @loader.load.each do |url, key|
        assert_equal([Encoding::UTF_8, Encoding::UTF_8],
                     [url.encoding, key.encoding], url)
      end
    end
  ensure
    FileUtils.rm_f(path)
  end
end
