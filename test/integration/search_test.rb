# coding: utf-8
require 'test_helper'
require 'integration_test_helper'

class SearchTest < ActionController::IntegrationTest
  def setup
    setup_database
    @types = []
    @categories = []
    @db_source.each do |key, value|
      @types << value[:type] unless @categories.include?(value[:type])
      @categories << value[:category] unless @categories.include?(value[:category])
    end
  end

  def teardown
    teardown_database
  end

  def test_top_page
    assert_visit "/search/"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}

    assert_visit "/search"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
  end

  def test_top_page_with_query
    assert_visit "/search/query/HTML"
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "HTML"],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"

    assert_visit "/search?search_request[type]=html&search_request[query]=HTML",
                 "/search/type/html/query/HTML"
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["type", "html",
                                 "query", "HTML"],
                 :drilldown => {:category => ["test"]},
                 :pagination => "1/1"

    assert_visit "/search?search_request[query]=HTML&search_request[base_params]=type%2Fhtml",
                 "/search/type/html/query/HTML"
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["type", "html",
                                 "query", "HTML"],
                 :drilldown => {:category => ["test"]},
                 :pagination => "1/1"

    assert_visit "/search?foobar"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
  end

  def test_result_with_query_including_slash
    assert_visit "/search/query/text%2Fhtml"
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["type", "html",
                                 "query", "HTML"],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"
  end

  def test_search_with_query_including_slash
    assert_visit "/search/"
    fill_in "search_request_query", :with => "text/html"
    click "Search"

    assert_equal "/search/query/text%2Fhtml", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "text/html"],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"
  end

  def test_no_entry_found
    assert_visit "/search/"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
    fill_in "search_request_query", :with => "notfound"
    click "Search"

    assert_equal "/search/query/notfound", current_path
    assert_not_found
  end

  def test_one_entry_found
    assert_visit "/search/"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
    fill_in "search_request_query", :with => "HTML entry"
    click "Search"

    assert_equal "/search/query/HTML%20entry", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "HTML",
                                 "query", "entry"],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"
  end

  def test_many_entries_found
    assert_visit "/search/"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
    fill_in "search_request_query", :with => "entry"
    click "Search"

    assert_equal "/search/query/entry", current_path
    assert_found :total_count => 14,
                 :entries_count => 10,
                 :topic_path => ["query", "entry"],
                 :drilldown => {:type => @types,
                                :category => @categories},
                 :pagination => "1/2"

    click_link "2"
    assert_equal "/search/query/entry", current_path
    assert_match /^\/search\/query\/entry?.*page=2/, current_full_path
    assert_found :total_count => 14,
                 :entries_count => 4,
                 :topic_path => ["query", "entry"],
                 :drilldown => {:type => @types,
                                :category => @categories},
                 :pagination => "2/2"
  end

  def test_topic_path
    test_one_entry_found
    click_link "html (1)"
    assert_equal "/search/query/HTML%20entry/type/html", current_path
    click_link "test (1)"
    assert_equal "/search/query/HTML%20entry/type/html/category/test", current_path

    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "HTML",
                                 "query", "entry",
                                 "type", "html",
                                 "category", "test"],
                 :pagination => "1/1"

    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-param='query']"+
                                "[@data-value='entry']"+
                 "/child::a").click
    assert_equal "/search/query/HTML/type/html/category/test", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "HTML",
                                 "type", "html",
                                 "category", "test"],
                 :pagination => "1/1"

    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-param='type']"+
                                "[@data-value='html']"+
                 "/child::a").click
    assert_equal "/search/query/HTML/category/test", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "HTML",
                                 "category", "test"],
                 :drilldown => {:type => ["html"]},
                 :pagination => "1/1"

    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-param='category']"+
                                "[@data-value='test']"+
                 "/child::a").click
    assert_equal "/search/query/HTML", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "HTML"],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"

    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-param='query']"+
                                "[@data-value='HTML']"+
                 "/child::a").click
    assert_equal "/search/", current_path
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
  end

  def test_drilldown
    assert_visit "/search/"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}

    click_link "xml (1)"
    assert_equal "/search/type/xml", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["type", "xml"],
                 :drilldown => {:category => @categories},
                 :pagination => "1/1"
  end

  def test_drilldown_after_search
    test_many_entries_found
    click_link "xml (1)"
    assert_equal "/search/query/entry/type/xml", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "entry",
                                 "type", "xml"],
                 :drilldown => {:category => @categories},
                 :pagination => "1/1"
  end

  def test_drilldown_twice
    test_many_entries_found

    click_link "xml (1)"
    assert_equal "/search/query/entry/type/xml", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "entry",
                                 "type", "xml"],
                 :drilldown => {:category => @categories},
                 :pagination => "1/1"

    click_link "test (1)"
    assert_equal "/search/query/entry/type/xml/category/test", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["query", "entry",
                                 "type", "xml",
                                 "category", "test"],
                 :pagination => "1/1"
  end

  def test_search_result_drilldown_after_search
    test_many_entries_found
    find(:xpath, "/descendant::li[@class='search_result_drilldown_category_item']/child::a").click
    assert_equal "/search/query/entry/category/test", current_path
    assert_found :total_count => 14,
                 :entries_count => 10,
                 :topic_path => ["query", "entry",
                                 "category", "test"],
                 :drilldown => {:type => @types},
                 :pagination => "1/2"
  end

  def test_search_after_drilldown
    test_drilldown

    fill_in "search_request_query", :with => "entry"
    click "Search"

    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => ["type", "xml",
                                 "query", "entry"],
                 :drilldown => {:category => ["test"]},
                 :pagination => "1/1"
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
    if options[:drilldown]
      assert_drilldown(options[:drilldown])
    else
      assert_no_drilldown
    end
  end

  def assert_found(options={})
    assert page.has_selector?(".search_form")
    assert page.has_selector?(".search_result")
    assert page.has_selector?(".search_result_items")
    assert page.has_no_selector?(".search_result_error_message")

    assert_total_count(options[:total_count]) unless options[:total_count].nil?
    assert_entries_count(options[:entries_count]) unless options[:entries_count].nil?
    assert_topic_path(options[:topic_path]) unless options[:topic_path].nil?
    if options[:drilldown]
      assert_drilldown(options[:drilldown])
    else
      assert_no_drilldown
    end
    if options[:pagination] && options[:pagination] != "1/1"
      assert_pagination options[:pagination]
    else
      assert_no_pagination
    end
  end

  def assert_not_found(options={})
    assert page.has_selector?(".search_form")
    assert page.has_selector?(".search_result")
    assert page.has_no_selector?(".search_result_items")
    assert page.has_selector?(".search_result_message")
    assert page.has_content?(I18n.t("search_result_not_found_message"))
    assert_no_pagination
    if options[:drilldown]
      assert_drilldown(options[:drilldown])
    else
      assert_no_drilldown
    end
  end

  def assert_total_count(count)
    assert page.has_content?(I18n.t("search_result_count", :count => count)),
           "the message for 'N entry(es) found?'\n#{page.body}"
  end

  def assert_entries_count(count)
    assert page.has_xpath?("/descendant::ol[@class='search_result_items']"+
                           "[count(child::li[@class='search_result_item'])=#{count}]"),
           "count of entry items\n#{page.body}"

    assert page.has_xpath?("/descendant::ol[@class='search_result_items']"+
                           "[count(descendant::li[@class='search_result_drilldown_category_item'])=#{count}]"),
           page.body
    assert page.has_xpath?("/descendant::ol[@class='search_result_items']"+
                           "[count(descendant::li[@class='search_result_drilldown_type_item'])=#{count}]"),
           page.body
  end

  def assert_topic_path(items)
    assert page.has_selector?(".topic_path")
    count = 0
    index = 0
    base_xpath = "/descendant::ol[@class='topic_path']"+
                 "/child::li[@class='topic_path_item']"
    while index < items.size do
      key = items[index]
      value = items[index+1]
      assert page.has_xpath?("#{base_xpath}[#{count+1}]"+
                                          "[@data-param='#{key}']"+
                                          "[@data-value='#{value}']"),
             "there should be a topic path item for #{key} = #{value} at #{count}\n#{page.body}"
      count += 1
      index += 2
    end
  end

  def assert_no_topic_path
    assert page.has_no_selector?(".topic_path"),
           "#{page.body}"
  end

  def assert_pagination(pagenum)
    assert page.has_selector?(".pagination")
    pagenum = pagenum.split("/")
    total = pagenum[1].to_i
    current = pagenum[0].to_i

    assert page.has_xpath?("/descendant::*[@class='pagination']"+
                           "/descendant::em[text()='#{current}']"),
           "#{page.body}"
    unless current == total
      assert page.has_xpath?("/descendant::*[@class='pagination']"+
                             "/descendant::a[last()-1][text()='#{total}']"),
             "#{page.body}"
    end
  end

  def assert_no_pagination
    assert page.has_no_selector?(".pagination"),
           "no pagination\n#{page.body}"
    assert page.has_no_selector?("#pagination_top"),
           "no pagination\n#{page.body}"
    assert page.has_no_selector?("#pagination_bottom"),
           "no pagination\n#{page.body}"
  end

  def assert_drilldown(groups)
    groups_xpath = "/descendant::ul[@class='drilldown_groups']"
    assert page.has_xpath?(groups_xpath)
    groups_count = 0
    groups.each do |param, group|
      group_xpath = "/descendant::li[@class='drilldown_group']"+
                                   "[@data-param='#{param}']"
      assert page.has_xpath?(group_xpath),
             "page should have drilldown group for #{param}\n#{page.body}"
      group_count = 0
      group.each do |value|
        assert page.has_xpath?("/descendant::li[@class='drilldown_item']"+
                                              "[@data-param='#{param}']"+
                                              "[@data-value='#{value}']"),
               "drilldown group for #{param} should have item for #{value}\n#{page.body}"
        group_count += 1
      end
      assert page.has_xpath?("#{group_xpath}[count(descendant::li)=#{group_count}]"),
             "drilldown group for #{param} should have #{group_count} item(s).\n#{page.body}"
      groups_count += 1
    end
    assert page.has_xpath?("#{groups_xpath}[count(child::li)=#{groups_count}]"),
           "page should have #{groups_count} drilldown group(s).\n#{page.body}"
  end

  def assert_no_drilldown
    assert page.has_no_selector?(".drilldown_groups"),
           "#{page.body}"
  end
end
