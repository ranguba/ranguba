# coding: utf-8

require 'test_helper'

class SearchRequestTest < ActiveSupport::TestCase

  def setup
    @request = SearchRequest.new
  end

  def test_new
    assert @request.valid?
    assert_equal "", @request.to_s
    assert_nil @request.query
    assert_nil @request.category
    assert_nil @request.type
    assert_equal 1, @request.page
    assert @request.empty?
  end

  def test_class_path
    path = SearchRequest.path(:base_path => "/search/",
                              :options => {:query => "foo",
                                           :type => "text/html"})
    assert_equal "/search/query/foo/type/text%2Fhtml", path
  end

  def test_path
    @request.query = "foo"
    @request.type = "text/html"
    assert_equal "/search/query/foo/type/text%2Fhtml",
                 @request.path(:base_path => "/search/")
    assert_equal "/search/query/foo",
                 @request.path(:base_path => "/search/", :without => :type)
    assert_equal "/search/query/bar/type/text%2Fhtml",
                 @request.path(:base_path => "/search/", :options => {:query => "bar"})
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

  def test_parse_valid_input
    @request.parse(nil)
    assert_valid

    @request.parse("")
    assert_valid
    
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

  def test_parse_mixed_order    
    @request.parse("category/cat/query/string/type/html")
    assert_valid(:to_s => "category/cat/query/string/type/html",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)

    @request.parse("type/html/category/cat/query/string")
    assert_valid(:to_s => "type/html/category/cat/query/string",
                 :query => "string",
                 :category => "cat",
                 :type => "html",
                 :empty => false)
  end

  def test_parse_unknown_param
    @request.parse("unknown/value")
    assert_invalid(:to_s => "unknown/value")

    @request.parse("query/string/unknown/value")
    assert_invalid(:to_s => "query/string/unknown/value",
                   :query => "string",
                   :empty => false)

    @request.parse("unknown/value/query/string")
    assert_invalid(:to_s => "unknown/value/query/string",
                   :query => "string",
                   :empty => false)
  end

  def test_parse_correctly_reset
    @request.parse("")
    assert_valid

    @request.parse("unknown/value")
    assert_invalid(:to_s => "unknown/value")

    @request.parse("")
    assert_valid
  end

  def test_clear
    @request = SearchRequest.new
    @request.parse("unknown/value")
    assert_invalid(:to_s => "unknown/value")

    @request.clear
    assert_valid
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

  def test_page
    @request.page = 1
    assert_equal 1, @request.page
    assert_equal "", @request.to_s

    @request.page = 2
    assert_equal 2, @request.page
    assert_equal "page/2", @request.to_s

    @request.page = "3"
    assert_equal 3, @request.page
    assert_equal "page/3", @request.to_s

    @request.page = nil
    assert_equal 1, @request.page
    assert_equal "", @request.to_s
  end

  def test_can_be_shorten
    @request.parse("page/1")
    assert @request.can_be_shorten?
    @request.parse("page/2")
    assert_false @request.can_be_shorten?

    @request.clear
    @request.page = 1
    assert_false @request.can_be_shorten?
    @request.page = 2
    assert_false @request.can_be_shorten?
  end

  def test_topic_path_items
    assert false
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
    options[:query] ||= nil
    options[:category] ||= nil
    options[:type] ||= nil
    options[:page] ||= 1
    options[:empty] = true if options[:empty].nil?

    assert_equal options[:to_s], @request.to_s
    assert_equal options[:query], @request.query
    assert_equal options[:category], @request.category
    assert_equal options[:type], @request.type
    assert_equal options[:page], @request.page
    assert_equal options[:empty], @request.empty?
  end
end
