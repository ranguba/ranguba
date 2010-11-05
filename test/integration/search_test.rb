# coding: utf-8
require 'test_helper'
require 'integration_test_helper'

class SearchTest < ActionController::IntegrationTest
  def setup
    setup_database
  end

  def teardown
    teardown_database
  end

  def test_top_page
    visit "/search/"
    assert_search_form

    visit "/search"
    assert_search_form

    visit "/search?foobar"
    assert_search_form
  end

  def test_result_with_query
    visit "/search/query/HTML"
    assert_search_result

    visit "/search/query/text%2Fhtml"
    assert_search_result
  end

  private
  def assert_search_form
    assert page.has_selector?('div.search_form')
    assert page.has_selector?('div.search_result')
  end

  def assert_search_result
    assert page.has_selector?('div.search_form')
    assert page.has_no_selector?('div.search_result')
  end
end
