# coding: utf-8

require 'test_helper'

class SearchRequestTest < ActiveSupport::TestCase

  def setup
    @search_request = SearchRequest.new
  end

  def test_new
    assert @search_request.valid?
    assert_equal "", @search_request.to_s
    assert_nil @search_request.query
    assert_nil @search_request.category
    assert_nil @search_request.type
    assert @search_request.empty?
  end

  def test_path
    path = SearchRequest.path(:base_path => "/search/",
                              :options => {:query => "foo",
                                           :type => "text/html"})
    assert_equal "/search/query/foo/type/text%2Fhtml", path
  end

  def test_new_with_params
    @search_request = SearchRequest.new({})
    assert_valid
    
    @search_request = SearchRequest.new(:query => "string")
    assert_valid(:to_s => "query/string",
                 :query => "string",
                 :empty => false)

    @search_request = SearchRequest.new(:query => "string",
                             :category => "cat")
    assert_valid(:to_s => "query/string/category/cat",
                 :query => "string",
                 :category => "cat",
                 :empty => false)

    @search_request = SearchRequest.new(:query => "string",
                             :type => "html")
    assert_valid(:to_s => "query/string/type/html",
                 :query => "string",
                 :type => "html",
                 :empty => false)

    @search_request = SearchRequest.new(:query => "string",
                             :category => "cat",
                             :type => "html")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)
  end

  def test_parse_valid_input
    @search_request.parse(nil)
    assert_valid

    @search_request.parse("")
    assert_valid
    
    @search_request.parse("query/string")
    assert_valid(:to_s => "query/string",
                 :query => "string",
                 :empty => false)
    
    @search_request.parse("/query/string")
    assert_valid(:to_s => "query/string",
                 :query => "string",
                 :empty => false)
    
    @search_request.parse("query/string/")
    assert_valid(:to_s => "query/string",
                 :query => "string",
                 :empty => false)
    
    @search_request.parse("/query/string/category/cat")
    assert_valid(:to_s => "query/string/category/cat",
                 :query => "string",
                 :category => "cat",
                 :empty => false)
    
    @search_request.parse("/query/string/type/html")
    assert_valid(:to_s => "query/string/type/html",
                 :query => "string",
                 :type => "html",
                 :empty => false)
    
    @search_request.parse("/query/string/category/cat/type/html")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)
  end

  def test_parse_mixed_order    
    @search_request.parse("category/cat/query/string/type/html")
    assert_valid(:to_s => "category/cat/query/string/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)

    @search_request.parse("type/html/category/cat/query/string")
    assert_valid(:to_s => "type/html/category/cat/query/string",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)
  end

  def test_parse_unknown_param
    @search_request.parse("unknown/value")
    assert_invalid(:to_s => "unknown/value")

    @search_request.parse("query/string/unknown/value")
    assert_invalid(:to_s => "query/string/unknown/value",
                   :query => "string",
                   :empty => false)

    @search_request.parse("unknown/value/query/string")
    assert_invalid(:to_s => "unknown/value/query/string",
                   :query => "string",
                   :empty => false)
  end

  def test_parse_correctly_reset
    @search_request.parse("")
    assert_valid

    @search_request.parse("unknown/value")
    assert_invalid(:to_s => "unknown/value")

    @search_request.parse("")
    assert_valid
  end

  def test_clear
    @search_request = SearchRequest.new
    @search_request.parse("unknown/value")
    assert_invalid(:to_s => "unknown/value")

    @search_request.clear
    assert_valid
  end

  def test_multibytes_io
    encoded = URI.encode("日本語")
    query_string = "query/#{encoded}"
    @search_request.parse(query_string)
    assert_valid(:to_s => query_string,
                 :query => "日本語",
                 :empty => false)

    @search_request.query = "日本"
    encoded = URI.encode("日本")
    assert_valid(:to_s => "query/#{encoded}",
                 :query => "日本",
                 :empty => false)
  end

  def test_slash_io
    query_string = "type/text%2Fhtml"
    @search_request.parse(query_string)
    assert_valid(:to_s => query_string,
                 :type => "text/html",
                 :empty => false)

    @search_request.type = "text/plain"
    assert_valid(:to_s => "type/text%2Fplain",
                 :type => "text/plain",
                 :empty => false)
  end

  private
  def assert_valid(options={})
    assert @search_request.valid?
    assert_properties(options)
  end

  def assert_invalid(options={})
    assert_false @search_request.valid?
    assert_properties(options)
  end

  def assert_properties(options={})
    options[:to_s] ||= ""
    options[:query] ||= nil
    options[:category] ||= nil
    options[:type] ||= nil
    options[:empty] = true if options[:empty].nil?

    assert_equal options[:to_s], @search_request.to_s
    assert_equal options[:query], @search_request.query
    assert_equal options[:category], @search_request.category
    assert_equal options[:type], @search_request.type
    assert_equal options[:empty], @search_request.empty?
  end
end
