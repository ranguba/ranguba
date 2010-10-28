# coding: utf-8

require 'test_helper'

class SearchQueryTest < ActiveSupport::TestCase

  def setup
    @query = Ranguba::SearchQuery.new
  end

  def test_new
    assert @query.valid?
    assert_equal "", @query.to_s
    assert_nil @query.hash
  end

  def test_new_with_params
    @query = Ranguba::SearchQuery.new("/query/string")
    assert_valid(:string => "query/string",
                 :hash => { :query => "string" })

    @query = Ranguba::SearchQuery.new(:query => "string")
    assert_valid(:string => "query/string",
                 :hash => { :query => "string" })
  end

  def test_parse_valid_input
    @query.parse("")
    assert_valid(:string => "",
                 :hash => nil)
    
    @query.parse("query/string")
    assert_valid(:string => "query/string",
                 :hash => { :query => "string" })
    
    @query.parse("/query/string")
    assert_valid(:string => "query/string",
                 :hash => { :query => "string" })
    
    @query.parse("query/string/")
    assert_valid(:string => "query/string",
                 :hash => { :query => "string" })
    
    @query.parse("/query/string/category/cat")
    assert_valid(:string => "query/string/category/cat",
                 :hash => { :query => "string",
                            :category => "cat" })
    
    @query.parse("/query/string/type/html")
    assert_valid(:string => "query/string/type/html",
                 :hash => { :query => "string",
                            :type => "html" })
    
    @query.parse("/query/string/category/cat/type/html")
    assert_valid(:string => "query/string/category/cat/type/html",
                 :hash => { :query => "string",
                            :category => "cat",
                            :type => "html" })
  end

  def test_parse_mixed_order    
    @query.parse("category/cat/query/string/type/html")
    assert_valid(:string => "category/cat/query/string/type/html",
                 :hash => { :category => "cat",
                            :query => "string",
                            :type => "html" })

    @query.parse("type/html/category/cat/query/string")
    assert_valid(:string => "type/html/category/cat/query/string",
                 :hash => { :type => "html",
                            :category => "cat",
                            :query => "string" })
  end

  def test_parse_unknown_param
    @query.parse("unknown/value")
    assert_invalid

    @query.parse("query/string/unknown/value")
    assert_invalid

    @query.parse("unknown/value/query/string")
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
    @query.hash = nil
    assert_valid(:string => "",
                 :hash => nil)

    @query.hash = {}
    assert_valid(:string => "",
                 :hash => nil)
    
    @query.hash = { :query => "string" }
    assert_valid(:string => "query/string",
                 :hash => { :query => "string" })

    @query.hash = { :query => "string",
                    :category => "cat" }
    assert_valid(:string => "query/string/category/cat",
                 :hash => { :query => "string",
                            :category => "cat" })

    @query.hash = { :query => "string",
                    :type => "html" }
    assert_valid(:string => "query/string/type/html",
                 :hash => { :query => "string",
                            :type => "html" })
    
    @query.hash = { :query => "string",
                    :category => "cat",
                    :type => "html" }
    assert_valid(:string => "query/string/category/cat/type/html",
                 :hash => { :query => "string",
                            :category => "cat",
                            :type => "html" })
  end

  def test_hash_unknown_param
    @query.hash = { :unknown => "value" }
    assert_invalid

    @query.hash = { :query => "string", :unknown => "value" }
    assert_invalid

    @query.hash = { :unknown => "value", :query => "string" }
    assert_invalid
  end

  def test_hash_correctly_reset
    @query.hash = {}
    assert_valid

    @query.hash = { :unknown => "value" }
    assert_invalid

    @query.hash = {}
    assert_valid
  end

  def test_multibytes_io
    encoded = URI.encode("日本語")
    query_string = "query/#{encoded}"
    @query.parse(query_string)
    assert_valid(:string => query_string,
                 :hash => { :query => "日本語" })

    @query.hash = {}
    assert_valid

    @query.hash = { :query => "日本語" }
    assert_valid(:string => query_string,
                 :hash => { :query => "日本語" })
  end

  private
  def assert_valid(options={})
    options[:string] ||= ""
    options[:hash] ||= nil
    assert @query.valid?
    assert_equal options[:string], @query.to_s
    assert_equal options[:hash], @query.hash
  end

  def assert_invalid(options={})
    assert_false @query.valid?
    assert_equal "", @query.to_s
    assert_equal nil, @query.hash
  end
end
