# coding: utf-8

require 'test_helper'

class SearchRequestTest < ActiveSupport::TestCase

  def setup
    @request = SearchRequest.new
  end

  def test_new
    assert_valid
  end

  def test_new_with_params
    @request = SearchRequest.new({})
    assert_valid
    
    @request = SearchRequest.new(:query => "string")
    assert_valid(:to_s => "query/string",
                 :query => "string",
                 :empty => false)

    @request = SearchRequest.new(:query => "string",
                                 :category => "cat")
    assert_valid(:to_s => "query/string/category/cat",
                 :query => "string",
                 :category => "cat",
                 :empty => false)

    @request = SearchRequest.new(:query => "string",
                                 :type => "html")
    assert_valid(:to_s => "query/string/type/html",
                 :query => "string",
                 :type => "html",
                 :empty => false)

    @request = SearchRequest.new(:query => "string",
                                 :category => "cat",
                                 :type => "html")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)
  end

  def test_new_with_base_params
    @request = SearchRequest.new(:query => "new",
                                 :base_params => "type/html")
    assert_valid(:to_s => "type/html/query/new",
                 :canonical => "query/new/type/html",
                 :query => "new",
                 :type => "html",
                 :empty => false)

    @request = SearchRequest.new(:query => "new",
                                 :base_params => "type/html/query/base")
    assert_valid(:to_s => "type/html/query/new",
                 :canonical => "query/new/type/html",
                 :query => "new",
                 :type => "html",
                 :empty => false)

    @request = SearchRequest.new(:type => "new",
                                 :base_params => "type/html/query/base")
    assert_valid(:to_s => "query/base/type/new",
                 :canonical => "query/base/type/new",
                 :query => "base",
                 :type => "new",
                 :empty => false)
  end

  def test_clear
    @request = SearchRequest.new
    @request.parse("unknown/value")
    assert_invalid(:to_s => "")

    @request.clear
    assert_valid
  end

  def test_ordered_keys
    assert_equal [:query, :category, :type], @request.ordered_keys
    @request.query = "q"
    assert_equal [:category, :type, :query], @request.ordered_keys
    @request.type = "t"
    assert_equal [:category, :query, :type], @request.ordered_keys
    @request.category = "c"
    assert_equal [:query, :type, :category], @request.ordered_keys
    @request.clear
    assert_equal [:query, :category, :type], @request.ordered_keys
    @request.parse("type/t/category/c/query/q")
    assert_equal [:type, :category, :query], @request.ordered_keys
  end

  def test_parse_valid_input
    @request.parse("query/string")
    assert_valid(:to_s => "query/string",
                 :query => "string",
                 :empty => false)
    
    @request.parse("/query/string")
    assert_valid(:to_s => "query/string",
                 :query => "string",
                 :empty => false)
    
    @request.parse("query/string/")
    assert_valid(:to_s => "query/string",
                 :query => "string",
                 :empty => false)
    
    @request.parse("/query/string/category/cat")
    assert_valid(:to_s => "query/string/category/cat",
                 :query => "string",
                 :category => "cat",
                 :empty => false)
    
    @request.parse("/query/string/type/html")
    assert_valid(:to_s => "query/string/type/html",
                 :query => "string",
                 :type => "html",
                 :empty => false)
    
    @request.parse("/query/string/category/cat/type/html")
    assert_valid(:to_s => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)
  end

  def test_parse_valid_blank_input
    @request.parse(nil)
    assert_valid

    @request.parse("")
    assert_valid
  end

  def test_parse_mixed_order    
    @request.parse("category/cat/query/string/type/html")
    assert_valid(:to_s => "category/cat/query/string/type/html",
                 :canonical => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)

    @request.parse("type/html/category/cat/query/string")
    assert_valid(:to_s => "type/html/category/cat/query/string",
                 :canonical => "query/string/category/cat/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)
  end

  def test_parse_unknown_param
    @request.parse("unknown/value")
    assert_invalid(:to_s => "")

    @request.parse("query/string/unknown/value")
    assert_invalid(:to_s => "query/string",
                   :query => "string",
                   :empty => false)

    @request.parse("unknown/value/query/string")
    assert_invalid(:to_s => "query/string",
                   :query => "string",
                   :empty => false)
  end

  def test_parse_correctly_reset_after_parsing
    @request.parse("")
    assert_valid

    @request.parse("unknown/value")
    assert_invalid(:to_s => "")

    @request.parse("")
    assert_valid

    @request = SearchRequest.new(:query => "query")
    @request.parse("")
    assert_valid

    @request = SearchRequest.new(:base_params => "query/base")
    @request.parse("")
    assert_valid
  end

  def test_path
    @request = SearchRequest.new(:query => "foo", :type => "html")
    assert_equal "/search/query/foo/type/html",
                 @request.path(:base_path => "/search/")
    assert_equal "/search/query/foo",
                 @request.path(:base_path => "/search/", :without => :type)
    assert_equal "/search/query/bar/type/html",
                 @request.path(:base_path => "/search/", :query => "bar")
  end

  def test_multibytes_io
    encoded = URI.encode("日本語")
    query_string = "query/#{encoded}"
    @request.parse(query_string)
    assert_valid(:to_s => query_string,
                 :query => "日本語",
                 :empty => false)

    @request.query = "日本"
    encoded = URI.encode("日本")
    assert_valid(:to_s => "query/#{encoded}",
                 :query => "日本",
                 :empty => false)
  end

  def test_slash_io
    query_string = "type/text%2Fhtml"
    @request.parse(query_string)
    assert_valid(:to_s => query_string,
                 :type => "text/html",
                 :empty => false)

    @request.type = "text/plain"
    assert_valid(:to_s => "type/text%2Fplain",
                 :type => "text/plain",
                 :empty => false)
  end

  def test_topic_path_items
    assert false
  end

  def test_class_path
    path = SearchRequest.path(:base_path => "/search/",
                              :query => "foo",
                              :type => "html")
    assert_equal "/search/query/foo/type/html", path
  end

  private
  def assert_valid(options={})
    assert @request.valid?
    assert_properties(options)
  end

  def assert_invalid(options={})
    assert_false @request.valid?
    assert_properties(options)
  end

  def assert_properties(options={})
    options[:to_s] ||= ""
    options[:canonical] ||= options[:to_s]
    options[:query] ||= nil
    options[:category] ||= nil
    options[:type] ||= nil
    options[:empty] = true if options[:empty].nil?

    assert_equal options[:to_s], @request.to_s
    assert_equal options[:canonical], @request.to_s(:canonical => true)
    assert_equal options[:query], @request.query
    assert_equal options[:category], @request.category
    assert_equal options[:type], @request.type
    assert_equal options[:empty], @request.empty?
  end
end
