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
    assert_visit "/search/"
    assert_search_form

    assert_visit "/search"
    assert_search_form
  end

  def test_top_page_with_query
    assert_visit "/search/query/HTML"
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "HTML"]

    assert_visit "/search?search_request[type]=html&search_request[query]=HTML",
                 "/search/type/html/query/HTML"
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["type", "html",
                                 "query", "HTML"]

    assert_visit "/search?search_request[query]=HTML&search_request[base_params]=type%2Fhtml",
                 "/search/type/html/query/HTML"
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["type", "html",
                                 "query", "HTML"]

    assert_visit "/search?foobar"
    assert_search_form
  end

  def test_result_with_query_including_slash
    assert_visit "/search/query/text%2Fhtml"
    assert_found
  end

  def test_no_entry_found
    assert_visit "/search/"
    assert_search_form
    fill_in "search_request_query", :with => "notfound"
    click "Search"

    assert_equal "/search/query/notfound", current_path
    assert_not_found
  end

  def test_one_entry_found
    assert_visit "/search/"
    assert_search_form
    fill_in "search_request_query", :with => "HTML entry"
    click "Search"

    assert_equal "/search/query/HTML%20entry", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "HTML",
                                 "query", "entry"]
    assert_no_pagination
  end

  def test_many_entries_found
    assert_visit "/search/"
    assert_search_form
    fill_in "search_request_query", :with => "entry"
    click "Search"

    assert_equal "/search/query/entry", current_path
    assert_found :total_count => 14,
                 :entries_count => 10,
                 :topic_path => ["query", "entry"]
    assert_pagination "1/2"

    click_link "2"
    assert_equal "/search/query/entry", current_path
    assert_match /^\/search\/query\/entry?.*page=2/, current_full_path
    assert_found :total_count => 14,
                 :entries_count => 4,
                 :topic_path => ["query", "entry"]
    assert_pagination "2/2"
  end

  private
  def current_full_path
    current_url.sub(/^\w+:\/\/[^\/]+/, "")
  end

  def assert_visit(path, expected_path=nil)
    visit path
    assert_equal (expected_path || path), current_full_path
  end

  def assert_search_form(options={})
    assert page.has_selector?(".search_form")
    assert page.has_no_selector?(".search_result")
    assert page.has_no_selector?(".search_result_error_message")
    assert_no_topic_path
    assert_no_pagination
  end

  def assert_found(options={})
    assert page.has_selector?(".search_form")
    assert page.has_selector?(".search_result")
    assert page.has_selector?(".search_result_items")
    assert page.has_no_selector?(".search_result_error_message")

    assert_total_count(options[:total_count]) unless options[:total_count].nil?
    assert_entries_count(options[:entries_count]) unless options[:entries_count].nil?
    assert_topic_path(options[:topic_path]) unless options[:topic_path].nil?
  end

  def assert_total_count(count)
    assert page.has_content?(I18n.t("search_result_count", :count => count)),
           "the message for 'N entry(es) found?'"
  end

  def assert_entries_count(count)
    assert page.has_xpath?("/descendant::ol[@class='search_result_items']"+
                           "[count(child::li[@class='search_result_item'])=#{count}]"),
           "count of entry items"
  end

  def assert_topic_path(items)
    assert page.has_selector?(".topic_path")
    count = 0
    index = 0
    base_xpath = "/descendant::ol[@class='topic_path']/child::li[@class='topic_path_item']"
    while index < items.size do
      key = items[index]
      value = items[index+1]
      assert page.has_xpath?("#{base_xpath}[#{count+1}][@data-param='#{key}' and @data-value='#{value}']"),
             "there should be a topic path item for #{key} = #{value} at #{count}"
      count += 1
      index += 2
    end
  end

  def assert_no_topic_path
    assert page.has_no_selector?(".topic_path")
  end

  def assert_not_found(options={})
    assert page.has_selector?(".search_form")
    assert page.has_selector?(".search_result")
    assert page.has_no_selector?(".search_result_items")
    assert page.has_selector?(".search_result_message")
    assert page.has_content?(I18n.t("search_result_not_found_message"))
    assert_no_pagination
  end

  def assert_pagination(pagenum)
    assert page.has_selector?(".pagination")
    pagenum = pagenum.split("/")
    total = pagenum[1].to_i
    current = pagenum[0].to_i

    assert page.has_xpath?("/descendant::*[@class='pagination']/descendant::em[text()='#{current}']")
    unless current == total
      assert page.has_xpath?("/descendant::*[@class='pagination']/descendant::a[last()-1][text()='#{total}']")
    end
  end

  def assert_no_pagination
    assert page.has_no_selector?(".pagination"),
           "no pagination"
    assert page.has_no_selector?("#pagination_top"),
           "no pagination"
    assert page.has_no_selector?("#pagination_bottom"),
           "no pagination"
  end
end
