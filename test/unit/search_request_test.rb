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
    
    @request = SearchRequest.new(:query => "q")
    assert_valid(:to_s => "query/q",
                 :query => "q",
                 :empty => false)

    @request = SearchRequest.new(:query => "q",
                                 :category => "c")
    assert_valid(:to_s => "query/q/category/c",
                 :query => "q",
                 :category => "c",
                 :empty => false)

    @request = SearchRequest.new(:query => "q",
                                 :type => "t")
    assert_valid(:to_s => "query/q/type/t",
                 :query => "q",
                 :type => "t",
                 :empty => false)

    @request = SearchRequest.new(:query => "q",
                                 :category => "c",
                                 :type => "t")
    assert_valid(:to_s => "query/q/category/c/type/t",
                 :query => "q",
                 :category => "c",
                 :type => "t",
                 :empty => false)

    @request = SearchRequest.new(:category => "c",
                                 :query => "q")
    assert_valid(:to_s => "category/c/query/q",
                 :canonical => "query/q/category/c",
                 :query => "q",
                 :category => "c",
                 :empty => false)
  end

  def test_new_with_base_params
    @request = SearchRequest.new(:query => "new",
                                 :base_params => "type/t")
    assert_valid(:to_s => "type/t/query/new",
                 :canonical => "query/new/type/t",
                 :query => "new",
                 :type => "t",
                 :empty => false)

    @request = SearchRequest.new(:query => "new",
                                 :base_params => "type/t/query/base")
    assert_valid(:to_s => "type/t/query/new",
                 :canonical => "query/new/type/t",
                 :query => "new",
                 :type => "t",
                 :empty => false)

    @request = SearchRequest.new(:type => "new",
                                 :base_params => "type/t/query/base")
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
    canonical = [:query, :category, :type]

    assert_equal canonical, @request.ordered_keys

    @request.query = "q"
    assert_equal [:category, :type, :query], @request.ordered_keys
    assert_equal canonical, @request.ordered_keys(:canonical => true)

    @request.type = "t"
    assert_equal [:category, :query, :type], @request.ordered_keys
    assert_equal canonical, @request.ordered_keys(:canonical => true)

    @request.category = "c"
    assert_equal [:query, :type, :category], @request.ordered_keys
    assert_equal canonical, @request.ordered_keys(:canonical => true)

    @request.clear
    assert_equal [:query, :category, :type], @request.ordered_keys
    assert_equal canonical, @request.ordered_keys(:canonical => true)

    @request.parse("type/t/category/c/query/q")
    assert_equal [:type, :category, :query], @request.ordered_keys
    assert_equal canonical, @request.ordered_keys(:canonical => true)

    @request = SearchRequest.new(:type => "n", :category => "c")
    assert_equal [:query, :type, :category], @request.ordered_keys
    assert_equal canonical, @request.ordered_keys(:canonical => true)
  end

  def test_parse_valid_input
    @request.parse("query/q")
    assert_valid(:to_s => "query/q",
                 :query => "q",
                 :empty => false)
    
    @request.parse("/query/q")
    assert_valid(:to_s => "query/q",
                 :query => "q",
                 :empty => false)
    
    @request.parse("query/q/")
    assert_valid(:to_s => "query/q",
                 :query => "q",
                 :empty => false)
    
    @request.parse("/query/q/category/c")
    assert_valid(:to_s => "query/q/category/c",
                 :query => "q",
                 :category => "c",
                 :empty => false)
    
    @request.parse("/query/q/type/t")
    assert_valid(:to_s => "query/q/type/t",
                 :query => "q",
                 :type => "t",
                 :empty => false)
    
    @request.parse("/query/q/category/c/type/t")
    assert_valid(:to_s => "query/q/category/c/type/t",
                 :query => "q",
                 :category => "c",
                 :type => "t",
                 :empty => false)
  end

  def test_parse_valid_blank_input
    @request.parse(nil)
    assert_valid

    @request.parse("")
    assert_valid
  end

  def test_parse_mixed_order    
    @request.parse("category/c/query/q/type/t")
    assert_valid(:to_s => "category/c/query/q/type/t",
                 :canonical => "query/q/category/c/type/t",
                 :query => "q",
                 :category => "c",
                 :type => "t",
                 :empty => false)

    @request.parse("type/t/category/c/query/q")
    assert_valid(:to_s => "type/t/category/c/query/q",
                 :canonical => "query/q/category/c/type/t",
                 :query => "q",
                 :category => "c",
                 :type => "t",
                 :empty => false)
  end

  def test_parse_unknown_param
    @request.parse("unknown/value")
    assert_invalid(:to_s => "")

    @request.parse("query/q/unknown/value")
    assert_invalid(:to_s => "query/q",
                   :query => "q",
                   :empty => false)

    @request.parse("unknown/value/query/q")
    assert_invalid(:to_s => "query/q",
                   :query => "q",
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

  def test_to_s
    @request = SearchRequest.new(:type => "t", :query => "q")

    assert_equal "type/t/query/q",
                 @request.to_s
    assert_equal "query/q/type/t",
                 @request.to_s(:canonical => true)

    assert_equal "query/q",
                 @request.to_s(:without => :type)
    assert_equal "query/q",
                 @request.to_s(:without => :type,
                               :canonical => true)

    # to_s must ignore search parameters
    assert_equal "type/t/query/q",
                 @request.to_s(:type => "new_t",
                               :query => "new_q")
    assert_equal "query/q/type/t",
                 @request.to_s(:query => "new_q",
                               :type => "new_t",
                               :canonical => true)
  end

  def test_path
    @request = SearchRequest.new(:type => "t", :query => "q")

    assert_equal "/search/type/t/query/q",
                 @request.path(:base_path => "/search/")
    assert_equal "/search/query/q/type/t",
                 @request.path(:base_path => "/search/",
                               :canonical => true)

    assert_equal "/search/query/q",
                 @request.path(:base_path => "/search/",
                               :without => :type)
    assert_equal "/search/query/q",
                 @request.path(:base_path => "/search/",
                               :without => :type,
                               :canonical => true)

    # path must ignore search parameters
    assert_equal "/search/type/t/query/q",
                 @request.path(:base_path => "/search/",
                               :type => "new_t",
                               :query => "new_q")
    assert_equal "/search/query/q/type/t",
                 @request.path(:base_path => "/search/",
                               :type => "new_t",
                               :query => "new_q",
                               :canonical => true)
  end

  def test_to_hash
    @request = SearchRequest.new(:type => "t", :query => "q")

    assert_equal({:type => "t", :query => "q"},
                 @request.to_hash)
    assert_equal({:query => "q", :type => "t"},
                 @request.to_hash(:canonical => true))

    assert_equal({:query => "q"},
                 @request.to_hash(:without => :type))
    assert_equal({:query => "q"},
                 @request.to_hash(:without => :type,
                                  :canonical => true))

    # to_hash must ignore search parameters
    assert_equal({:type => "t", :query => "q"},
                 @request.to_hash(:type => "new_t",
                                  :query => "new_q"))
    assert_equal({:query => "q", :type => "t"},
                 @request.to_hash(:type => "new_t",
                                  :query => "new_q",
                                  :canonical => true))
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

  def test_to_readable_string
    @request.type = "t"
    @request.query = "q"

    type = I18n.t("topic_path_item_label",
                  :type => I18n.t("column_type_name"),
                  :value => "t")
    separator = I18n.t("search_conditions_delimiter")
    
    assert_equal [type, "q"].join(separator), @request.to_readable_string
    assert_equal ["q", type].join(separator), @request.to_readable_string(:canonical => true)
    assert_equal type, @request.to_readable_string(:without => :query)
  end

  def test_topic_path_items
    @request.type = "t"
    @request.query = "q1 q2"

    type = {:label => I18n.t("topic_path_item_label",
                             :type => I18n.t("column_type_name"),
                             :value => "t"),
            :title => "",
            :path => "",
            :reduce_title => I18n.t("topic_path_reduce_item_label",
                                    :type => I18n.t("column_type_name"),
                                    :value => "t"),
            :reduce_path => "",
            :param => :type,
            :value => "t"}
    query1 = {:label => "q1",
              :title => "",
              :path => "",
              :reduce_title => I18n.t("topic_path_reduce_query_item_label",
                                      :value => "q1"),
              :reduce_path => "",
              :param => :query,
              :value => "q1"}
    query2 = {:label => "q2",
              :title => "",
              :path => "",
              :reduce_title => I18n.t("topic_path_reduce_query_item_label",
                                      :value => "q2"),
              :reduce_path => "",
              :param => :query,
              :value => "q2"}

    topic_path_request = SearchRequest.new

    topic_path_request.type = "t"
    type[:title] = topic_path_request.to_readable_string
    type[:path] = "/base/type/t"
    type[:reduce_path] = "/base/query/q1%20q2"

    topic_path_request.query = "q1"
    query1[:title] = topic_path_request.to_readable_string
    query1[:path] = "/base/type/t/query/q1"
    query1[:reduce_path] = "/base/type/t/query/q2"

    topic_path_request.query = "q1 q2"
    query2[:title] = topic_path_request.to_readable_string
    query2[:path] = "/base/type/t/query/q1%20q2"
    query2[:reduce_path] = "/base/type/t/query/q1"

    assert_equal [type, query1, query2],
                 @request.topic_path_items(:base_path => "/base")


    topic_path_request = SearchRequest.new

    topic_path_request.query = "q1"
    query1[:title] = topic_path_request.to_readable_string
    query1[:path] = "/base/query/q1"
    query1[:reduce_path] = "/base/query/q2/type/t"

    topic_path_request.query = "q1 q2"
    query2[:title] = topic_path_request.to_readable_string
    query2[:path] = "/base/query/q1%20q2"
    query2[:reduce_path] = "/base/query/q1/type/t"

    topic_path_request.type = "t"
    type[:title] = topic_path_request.to_readable_string
    type[:path] = "/base/query/q1%20q2/type/t"
    type[:reduce_path] = "/base/query/q1%20q2"

    assert_equal [query1, query2, type],
                 @request.topic_path_items(:base_path => "/base", :canonical => true)
  end

  def test_class_path
    path = SearchRequest.path(:base_path => "/search/",
                              :query => "q",
                              :type => "t")
    assert_equal "/search/query/q/type/t", path

    path = SearchRequest.path(:base_path => "/search/",
                              :type => "t",
                              :query => "q")
    assert_equal "/search/type/t/query/q", path

    path = SearchRequest.path(:base_path => "/search/",
                              :type => "t",
                              :query => "q",
                              :canonical => true)
    assert_equal "/search/query/q/type/t", path
  end

  def test_class_ecncode_parameter
    assert_equal "abcABC%20%2F%3F", SearchRequest.encode_parameter("abcABC /?")
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
