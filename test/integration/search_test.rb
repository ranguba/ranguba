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
  end

  def test_result_with_query_including_slash
    visit "/search/query/text%2Fhtml"
    assert_search_result
  end

  def test_do_search
    visit "/search/"
    assert_search_form
    fill_in "search_request_query", :with => "HTML"
    click "Search"
    assert_search_result
  end

  private
  def assert_search_form(options={})
    assert page.has_selector?(".search_form")
    assert page.has_no_selector?(".search_result")
    assert page.has_no_selector?(".search_result_error_message")
  end

  def assert_search_result(options={})
    assert page.has_selector?(".search_form")
    assert page.has_selector?(".search_result")
    assert page.has_selector?(".search_result_items")
    assert page.has_no_selector?(".search_result_error_message")
  end
end
