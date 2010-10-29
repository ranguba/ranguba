# coding: utf-8

require 'test_helper'

class DrilldownItemTest < ActiveSupport::TestCase

  def setup
    @item = DrilldownItem.new
  end

  def test_to_hash
    @item.param = "type"
    @item.value = "text/html"
    assert_equal({:type => "text/html"}, @item.to_hash)
    assert_equal({:type => "text/html"}, @item.to_hash(:type => "unknown"))
    assert_equal({:type => "text/html", :query => "foo"},
                 @item.to_hash(:query => "foo"))
  end

  def test_path
    @item.param = "type"
    @item.value = "text/html"
    path = @item.path(:base_path => "/search/",
                      :base_options => {:query => "foo",
                                        :type => "unknown"})
    assert_equal "/search/query/foo/type/text%2Fhtml", path
  end

end
