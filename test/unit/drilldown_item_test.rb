# coding: utf-8

require 'test_helper'

class DrilldownItemTest < ActiveSupport::TestCase

  def setup
    @item = DrilldownItem.new
  end

  def test_new
    assert_valid
  end

  def test_new_with_params
    @item = DrilldownItem.new({})
    assert_valid
    
    @item = DrilldownItem.new(:base_params => "query/q",
                              :param => :type,
                              :value => "t")
    assert_valid(:to_s => "query/q/type/t",
                 :query => "q",
                 :type => "t",
                 :param => :type,
                 :value => "t",
                 :empty => false)

    @item = DrilldownItem.new(:base_params => "category/c",
                              :param => :query,
                              :value => "q")
    assert_valid(:to_s => "category/c/query/q",
                 :canonical => "query/q/category/c",
                 :category => "c",
                 :query => "q",
                 :param => :query,
                 :value => "q",
                 :empty => false)
  end

  def test_to_hash
    @item = DrilldownItem.new(:base_params => "type/t")
    @item.param = :category
    @item.value = "c"
    assert_equal({:type => "t", :category => "c"}, @item.to_hash)
    assert_equal({:category => "c", :type => "t"}, @item.to_hash(:canonical => true))
    assert_equal({:type => "t", :category => "c"}, @item.to_hash(:query => "foo"))
  end

  def test_to_s
    @item = DrilldownItem.new(:base_params => "type/t")
    @item.param = :category
    @item.value = "c"
    assert_equal "type/t/category/c", @item.to_s
    assert_equal "category/c/type/t", @item.to_s(:canonical => true)
    assert_equal "type/t/category/c", @item.to_s(:query => "q")
  end

  def test_path
    @item = DrilldownItem.new(:base_params => "type/t")
    @item.param = :category
    @item.value = "c"
    assert_equal "/base/type/t/category/c", @item.path(:base_path => "/base/")
    assert_equal "/base/category/c/type/t", @item.path(:base_path => "/base/", :canonical => true)
    assert_equal "/base/type/t/category/c", @item.path(:base_path => "/base/", :query => "q")
  end

  private
  def assert_valid(options={})
    assert @item.valid?
    assert_properties(options)
  end

  def assert_invalid(options={})
    assert_false @item.valid?
    assert_properties(options)
  end

  def assert_properties(options={})
    options[:to_s] ||= ""
    options[:canonical] ||= options[:to_s]
    options[:query] ||= nil
    options[:category] ||= nil
    options[:type] ||= nil
    options[:param] ||= nil
    options[:value] ||= nil
    options[:count] ||= 0
    options[:empty] = true if options[:empty].nil?

    assert_equal options[:to_s], @item.to_s
    assert_equal options[:canonical], @item.to_s(:canonical => true)
    assert_equal options[:query], @item.query
    assert_equal options[:category], @item.category
    assert_equal options[:type], @item.type
    assert_equal options[:param], @item.param
    assert_equal options[:value], @item.value
    assert_equal options[:count], @item.count
    assert_equal options[:empty], @item.empty?
  end

end
