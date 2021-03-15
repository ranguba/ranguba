require 'test_helper'

class Ranguba::TemplateTest < ActiveSupport::TestCase
  def setup
    @ranguba_template = Ranguba::Template.new
  end

  def test_tile
    assert_equal "title\n", @ranguba_template.title
  end

  def test_header
    assert_equal "header\n", @ranguba_template.header
  end

  def test_footer
    assert_equal "footer\n", @ranguba_template.footer
  end
end
