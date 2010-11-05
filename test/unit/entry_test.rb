require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  def setup
    @entry = Entry.new
  end

  def test_summary_by_head
    @entry.body = "0123456789"
    assert_equal "012-", @entry.summary(:size => 3, :separator => "-")
  end
end
