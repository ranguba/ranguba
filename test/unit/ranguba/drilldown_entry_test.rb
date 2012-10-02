# -* coding: utf-8 -*-

require 'test_helper'

class Ranguba::DrilldownEntryTest < ActiveSupport::TestCase

  def setup
    @klass = Ranguba::DrilldownEntry
    @basic = @klass.new
    @item = @basic
  end

  def test_new
    assert !@item.query_item?
  end

  def test_new_with_params
    @item = @klass.new({})
    assert_properties

    @item = @klass.new(:key => :type, :value => "t")
    assert_properties(:key => :type, :value => "t")

    @item = @klass.new(:key => :query, :value => "q")
    assert_properties(:key => :query, :value => "q")
  end

  def test_path
    @item.key = :category
    @item.value = "c"
    assert_equal "category/c", @item.path
  end

  private

  def assert_properties(options={})
    options[:key] ||= nil
    options[:value] ||= nil
    options[:count] ||= 0
    assert_equal options[:key], @item.key
    assert_equal options[:value], @item.value
    assert_equal options[:count], @item.count
  end

end
