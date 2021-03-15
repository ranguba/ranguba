# -* coding: utf-8 -*-

require 'test_helper'

class Ranguba::DrilldownEntryTest < ActiveSupport::TestCase
  def setup
    @entry = Ranguba::DrilldownEntry.new(key: :type,
                                         value: "html",
                                         count: 10)
  end

  def test_path
    assert_equal("type/html", @entry.path)
  end

  def test_query_item?
    assert do
      not @entry.query_item?
    end
  end
end
