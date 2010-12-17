# coding: utf-8
require 'test_helper'

class Ranguba::SearchRequestTest < ActiveSupport::TestCase

  def setup
    @klass = Ranguba::SearchRequest
    @basic = @klass.new
    @request = @basic
  end

  def test_new
    assert_valid
  end

  def test_new__empty_hash
    @request = @klass.new({})
    assert_valid
  end

  def test_new_with_empty_path_info_query
    @request = @klass.new('', :query => "q")
    assert_valid(:to_s => "query/q",
                 :query => "q",
                 :empty => false)
  end

  def test_new_with_empty_path_info_query_category

    @request = @klass.new('',
                          :query => "q",
                          :category => "c")
    assert_valid(:to_s => "query/q/category/c",
                 :query => "q",
                 :category => "c",
                 :empty => false)
  end

  def test_new_with_empty_path_info_query_type
    @request = @klass.new('',
                          :query => "q",
                          :type => "t")
    assert_valid(:to_s => "query/q/type/t",
                 :query => "q",
                 :type => "t",
                 :empty => false)
  end

  def test_new_with_empty_path_info_query_category_type
    @request = @klass.new('',
                          :query => "q",
                          :category => "c",
                          :type => "t")
    assert_valid(:to_s => "query/q/category/c/type/t",
                 :query => "q",
                 :category => "c",
                 :type => "t",
                 :empty => false)
  end

  def test_new_with_empty_path_info_category_query
    @request = @klass.new('',
                          :category => "c",
                          :query => "q")
    assert_valid(:to_s => "category/c/query/q",
                 :canonical => "query/q/category/c",
                 :query => "q",
                 :category => "c",
                 :empty => false)
  end

  def test_new_with_path_info_without_original_query
    @request = @klass.new("type/t", :query => "new")
    assert_valid(:to_s => "type/t/query/new",
                 :canonical => "query/new/type/t",
                 :query => "new",
                 :type => "t",
                 :empty => false)
  end

  def test_new_with_path_info_original_query
    @request = @klass.new("type/t/query/base", :query => "new")
    assert_valid(:to_s => "type/t/query/new",
                 :canonical => "query/new/type/t",
                 :query => "new",
                 :type => "t",
                 :empty => false)
  end

  def test_new_with_path_info_original_type_new_type
    @request = @klass.new("type/t/query/base", :type => "new")
    assert_valid(:to_s => "query/base/type/new",
                 :canonical => "query/base/type/new",
                 :query => "base",
                 :type => "new",
                 :empty => false)
  end

  def test_new_with_empty_path_info_query_space
    @request = @klass.new('', :query => "q r")
    assert_valid(:to_s => "query/q+r",
                 :query => "q r",
                 :empty => false)
  end

  def test_new_with_empty_path_info_query_fillwidth_space
    @request = @klass.new('', :query => "q　r")
    assert_valid(:to_s => "query/q+r",
                 :query => "q r",
                 :empty => false)
  end

  def test_clear
    @request = @klass.new
    @request.parse("unknown/value")
    assert_invalid(:to_s => "")

    @request.clear
    assert_valid
  end

  CANONICAL_KEYS = [:query, :category, :type]

  def test_ordered_keys_shuffle_keys
    assert_equal(CANONICAL_KEYS, @request.ordered_keys)

    @request.query = "q"
    assert_equal([:category, :type, :query], @request.ordered_keys)
    assert_equal(CANONICAL_KEYS, @request.ordered_keys(:canonical => true))

    @request.type = "t"
    assert_equal([:category, :query, :type], @request.ordered_keys)
    assert_equal(CANONICAL_KEYS, @request.ordered_keys(:canonical => true))

    @request.category = "c"
    assert_equal([:query, :type, :category], @request.ordered_keys)
    assert_equal(CANONICAL_KEYS, @request.ordered_keys(:canonical => true))

    @request.clear
    assert_equal([:query, :category, :type], @request.ordered_keys)
    assert_equal(CANONICAL_KEYS, @request.ordered_keys(:canonical => true))
  end

  def test_ordered_keys_complete_path_info
    @request = @klass.new("/search/type/t/category/c/query/q")
    assert_equal([:type, :category, :query], @request.ordered_keys)
    assert_equal(CANONICAL_KEYS, @request.ordered_keys(:canonical => true))
  end

  def test_ordered_keys_empry_path_info
    @request = @klass.new("", :type => "n", :category => "c")
    assert_equal([:query, :type, :category], @request.ordered_keys)
    assert_equal(CANONICAL_KEYS, @request.ordered_keys(:canonical => true))
  end

  def test_parse_valid_input_normal_path_info
    @request = @klass.new("query/q")
    assert_valid(:to_s => "query/q",
                 :query => "q",
                 :empty => false)
  end

  def test_parse_valid_input_preceding_slash
    @request = @klass.new("/query/q")
    assert_valid(:to_s => "query/q",
                 :query => "q",
                 :empty => false)
  end

  def test_parse_valid_input_trailing_slash
    @request = @klass.new("query/q/")
    assert_valid(:to_s => "query/q",
                 :query => "q",
                 :empty => false)
  end

  def test_parse_valid_input_query_category
    @request = @klass.new("/query/q/category/c")
    assert_valid(:to_s => "query/q/category/c",
                 :query => "q",
                 :category => "c",
                 :empty => false)
  end

  def test_parse_valid_input_query_type
    @request = @klass.new("/query/q/type/t")
    assert_valid(:to_s => "query/q/type/t",
                 :query => "q",
                 :type => "t",
                 :empty => false)
  end

  def test_parse_valid_input_query_category_type
    @request = @klass.new("/query/q/category/c/type/t")
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
    @request = @klass.new("category/c/query/q/type/t")
    assert_valid(:to_s => "category/c/query/q/type/t",
                 :canonical => "query/q/category/c/type/t",
                 :query => "q",
                 :category => "c",
                 :type => "t",
                 :empty => false)

    @request = @klass.new("type/t/category/c/query/q")
    assert_valid(:to_s => "type/t/category/c/query/q",
                 :canonical => "query/q/category/c/type/t",
                 :query => "q",
                 :category => "c",
                 :type => "t",
                 :empty => false)
  end

  def test_parse_unknown_param
    @request = @klass.new("unknown/value")
    assert_invalid(:to_s => "")

    @request = @klass.new("query/q/unknown/value")
    assert_invalid(:to_s => "query/q",
                   :query => "q",
                   :empty => false)

    @request = @klass.new("unknown/value/query/q")
    assert_invalid(:to_s => "query/q",
                   :query => "q",
                   :empty => false)
  end

  def test_to_s
    @request = @klass.new("", :type => "t", :query => "q")

    assert_equal("type/t/query/q",
                 @request.to_s)
    assert_equal "query/q/type/t",
                 @request.to_s(:canonical => true)

    assert_equal("query/q",
                 @request.to_s(:without => :type))
    assert_equal("query/q",
                 @request.to_s(:without => :type,
                               :canonical => true))
  end

  def test_to_s_must_ignore_search_parameters
    @request = @klass.new("", :type => "t", :query => "q")

    assert_equal("type/t/query/q",
                 @request.to_s(:type => "new_t",
                               :query => "new_q"))
    assert_equal("query/q/type/t",
                 @request.to_s(:query => "new_q",
                               :type => "new_t",
                               :canonical => true))
  end

  def test_to_hash
    @request = @klass.new('', :type => "t", :query => "q")

    assert_equal({:type => "t", :query => "q"},
                 @request.to_hash)
    assert_equal({:query => "q", :type => "t"},
                 @request.to_hash(:canonical => true))

    assert_equal({:query => "q"},
                 @request.to_hash(:without => :type))
    assert_equal({:query => "q"},
                 @request.to_hash(:without => :type,
                                  :canonical => true))
  end

  def test_to_hash_must_ignore_search_parameters
    @request = @klass.new('', :type => "t", :query => "q")

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
    @request = @klass.new(query_string)
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
    @request = @klass.new(query_string)
    assert_valid(:to_s => query_string,
                 :type => "text/html",
                 :empty => false)

    @request.type = "text/plain"
    assert_valid(:to_s => "type/text%2Fplain",
                 :type => "text/plain",
                 :empty => false)
  end

  def test_to_readable_string
    I18n.locale = :en
    I18n.backend.store_translations(:en, { 'type' => { 't' => 't'}})
    @request.type = "t"
    @request.query = "q"

    type = I18n.t("topic_path_item_label",
                  :type => I18n.t("column_type_name"),
                  :value => "t")
    separator = I18n.t("search_conditions_delimiter")

    assert_equal([type, "q"].join(separator), @request.to_readable_string)
    assert_equal(["q", type].join(separator), @request.to_readable_string(:canonical => true))
    assert_equal(type, @request.to_readable_string(:without => :query))
  end

  def test_topic_path
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

    query1 = Ranguba::TopicPathItem.new(:query, 'q1')
    query1.value_label = 'q1'
    query2 = Ranguba::TopicPathItem.new(:query, 'q2')
    query2.value_label = 'q2'
    type   = Ranguba::TopicPathItem.new(:type, 't')

    assert_equal('type/t/query/q1+q2', @request.topic_path.search_request)
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

    assert_equal(options[:to_s], @request.to_s)
    assert_equal(options[:canonical], @request.to_s(:canonical => true))
    assert_equal(options[:query], @request.query)
    assert_equal(options[:category], @request.category)
    assert_equal(options[:type], @request.type)
    assert_equal(options[:empty], @request.empty?)
  end
end
