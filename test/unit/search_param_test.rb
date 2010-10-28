# coding: utf-8

require 'test_helper'

class SearchParamTest < ActiveSupport::TestCase

  def setup
    @param = SearchParam.new
  end

  def test_new
    assert @param.valid?
    assert_equal "", @param.to_s
    assert_nil @param.query
    assert_nil @param.category
    assert_nil @param.type
  end

  def test_new_with_params
    @param = SearchParam.new({})
    assert_valid
    
    @param = SearchParam.new(:query => "string")
    assert_valid(:to_s => "query/string",
                 :query => "string")

    @param = SearchParam.new(:query => "string",
                             :category => "cat")
    assert_valid(:to_s => "query/string/category/cat",
                 :query => "string",
                 :category => "cat")

    @param = SearchParam.new(:query => "string",
                             :type => "html")
    assert_valid(:to_s => "query/string/type/html",
                 :query => "string",
                 :type => "html")

    @param = SearchParam.new(:query => "string",
                             :category => "cat",
                             :type => "html")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html")
  end

  def test_parse_valid_input
    @param.parse("")
    assert_valid
    
    @param.parse("query/string")
    assert_valid(:to_s => "query/string",
                 :query => "string")
    
    @param.parse("/query/string")
    assert_valid(:to_s => "query/string",
                 :query => "string")
    
    @param.parse("query/string/")
    assert_valid(:to_s => "query/string",
                 :query => "string")
    
    @param.parse("/query/string/category/cat")
    assert_valid(:to_s => "query/string/category/cat",
                 :query => "string",
                 :category => "cat")
    
    @param.parse("/query/string/type/html")
    assert_valid(:to_s => "query/string/type/html",
                 :query => "string",
                 :type => "html")
    
    @param.parse("/query/string/category/cat/type/html")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html")
  end

  def test_parse_mixed_order    
    @param.parse("category/cat/query/string/type/html")
    assert_valid(:to_s => "category/cat/query/string/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html")

    @param.parse("type/html/category/cat/query/string")
    assert_valid(:to_s => "type/html/category/cat/query/string",
                 :query => "string",
                 :category => "cat",
                 :type => "html")
  end

  def test_parse_unknown_param
    @param.parse("unknown/value")
    assert_invalid(:to_s => "unknown/value")

    @param.parse("query/string/unknown/value")
    assert_invalid(:to_s => "query/string/unknown/value",
                   :query => "string")

    @param.parse("unknown/value/query/string")
    assert_invalid(:to_s => "unknown/value/query/string",
                   :query => "string")
  end

  def test_parse_correctly_reset
    @param.parse("")
    assert_valid

    @param.parse("unknown/value")
    assert_invalid(:to_s => "unknown/value")

    @param.parse("")
    assert_valid
  end

  def test_clear
    @param = SearchParam.new
    @param.parse("unknown/value")
    assert_invalid(:to_s => "unknown/value")

    @param.clear
    assert_valid
  end

  def test_multibytes_io
    encoded = URI.encode("日本語")
    query_string = "query/#{encoded}"
    @param.parse(query_string)
    assert_valid(:to_s => query_string,
                 :query => "日本語")

    @param.query = nil
    assert_valid

    @param.query = "日本語"
    assert_valid(:to_s => query_string,
                 :query => "日本語")
  end

  private
  def assert_valid(options={})
    assert @param.valid?
    assert_properties(options)
  end

  def assert_invalid(options={})
    assert_false @param.valid?
    assert_properties(options)
  end

  def assert_properties(options={})
    options[:to_s] ||= ""
    options[:query] ||= nil
    options[:category] ||= nil
    options[:type] ||= nil

    assert_equal options[:to_s], @param.to_s
    assert_equal options[:query], @param.query
    assert_equal options[:category], @param.category
    assert_equal options[:type], @param.type
  end
end
