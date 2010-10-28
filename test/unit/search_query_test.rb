# coding: utf-8

require 'test_helper'

class SearchQueryTest < ActiveSupport::TestCase

  def setup
    @query = SearchQuery.new
  end

  def test_new
    assert @query.valid?
    assert_equal "", @query.to_s
    assert_nil @query.query
    assert_nil @query.category
    assert_nil @query.type
  end

  def test_new_with_params
    @query = SearchQuery.new("/query/string")
    assert_valid(:to_s => "query/string",
                 :query => "string")

    @query = SearchQuery.new(:query => "string")
    assert_valid(:to_s => "query/string",
                 :query => "string")
  end

  def test_parse_valid_input
    @query.parse("")
    assert_valid
    
    @query.parse("query/string")
    assert_valid(:to_s => "query/string",
                 :query => "string")
    
    @query.parse("/query/string")
    assert_valid(:to_s => "query/string",
                 :query => "string")
    
    @query.parse("query/string/")
    assert_valid(:to_s => "query/string",
                 :query => "string")
    
    @query.parse("/query/string/category/cat")
    assert_valid(:to_s => "query/string/category/cat",
                 :query => "string",
                 :category => "cat")
    
    @query.parse("/query/string/type/html")
    assert_valid(:to_s => "query/string/type/html",
                 :query => "string",
                 :type => "html")
    
    @query.parse("/query/string/category/cat/type/html")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html")
  end

  def test_parse_mixed_order    
    @query.parse("category/cat/query/string/type/html")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html")

    @query.parse("type/html/category/cat/query/string")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html")
  end

  def test_parse_unknown_param
    @query.parse("unknown/value")
    assert_invalid

    @query.parse("query/string/unknown/value")
    assert_invalid

    @query.parse("unknown/value/query/string")
    assert_invalid
  end

  def test_parse_not_string
    @query.parse(:query => "string")
    assert_invalid
  end

  def test_parse_correctly_reset
    @query.parse("")
    assert_valid

    @query.parse("unknown/value")
    assert_invalid

    @query.parse("")
    assert_valid
  end

  def test_hash_valid_input
    @query = SearchQuery.new
    assert_valid

    @query = SearchQuery.new({})
    assert_valid
    
    @query = SearchQuery.new(:query => "string")
    assert_valid(:to_s => "query/string",
                 :query => "string")

    @query = SearchQuery.new(:query => "string",
                             :category => "cat")
    assert_valid(:to_s => "query/string/category/cat",
                 :query => "string",
                 :category => "cat")

    @query = SearchQuery.new(:query => "string",
                             :type => "html")
    assert_valid(:to_s => "query/string/type/html",
                 :query => "string",
                 :type => "html")

    @query = SearchQuery.new(:query => "string",
                             :category => "cat",
                             :type => "html")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html")
  end

  def test_hash_unknown_param
    @query = SearchQuery.new(:unknown => "value")
    assert_invalid

    @query = SearchQuery.new(:query => "string", :unknown => "value")
    assert_invalid
  end

  def test_clear
    @query = SearchQuery.new(:unknown => "value")
    assert_invalid

    @query.clear
    assert_valid
  end

  def test_multibytes_io
    encoded = URI.encode("日本語")
    query_string = "query/#{encoded}"
    @query.parse(query_string)
    assert_valid(:to_s => query_string,
                 :query => "日本語")

    @query.query = nil
    assert_valid

    @query.query = "日本語"
    assert_valid(:to_s => query_string,
                 :query => "日本語")
  end

  private
  def assert_valid(options={})
    options[:to_s] ||= ""
    options[:query] ||= nil
    options[:category] ||= nil
    options[:type] ||= nil

    assert @query.valid?
    assert_equal options[:to_s], @query.to_s
    assert_equal options[:query], @query.query
    assert_equal options[:category], @query.category
    assert_equal options[:type], @query.type
  end

  def assert_invalid(options={})
    assert_false @query.valid?
    assert_equal "", @query.to_s
  end
end
