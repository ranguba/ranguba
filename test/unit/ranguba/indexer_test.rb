# -*- coding: utf-8 -*-
require 'test_helper'
require 'ranguba/indexer'

class Ranguba::IndexerTest < ActiveSupport::TestCase

  def setup
    @indexer = Ranguba::Indexer.new([])
  end

  def test_valid_utf8_with_empty_string
    assert_valid_utf8("")
  end

  def test_valid_utf8_with_ascii_only_string
    assert_valid_utf8("abcdefg123")
  end

  def test_valid_utf8_with_white_space_string
    assert_valid_utf8(" \t\n")
  end

  def test_valid_utf8_with_utf8_string__hiragana
    assert_valid_utf8("あいうえお")
  end

  def test_valid_utf8_with_false_positive_string
    # "フォーマット集".force_encoding('sjis').valid_encoding? # => true
    assert_valid_utf8("フォーマット集")
  end

  def test_valid_utf8_with_utf8_string__kanji
    assert_valid_utf8("日本語の漢字を表現します")
  end

  def test_valid_utf8_with_sjis_string__hiragana
    assert_not_valid_utf8("あいうえお".encode('Shift_JIS'))
  end

  def test_valid_utf8_with_sjis_string__kanji
    assert_not_valid_utf8("日本語の漢字を表現します".encode('Shift_JIS'))
  end

  def test_valid_utf8_with_eucjp_string__hiragana
    assert_not_valid_utf8("あいうえお".encode('EUC-JP'))
  end

  def test_valid_utf8_with_eucjp_string__kanji
    assert_not_valid_utf8("日本語の漢字を表現します".encode('EUC-JP'))
  end

  private

  def assert_valid_utf8(string)
    assert_true(@indexer.send(:valid_utf8?, string))
  end

  def assert_not_valid_utf8(string)
    assert_false(@indexer.send(:valid_utf8?, string))
  end
end
