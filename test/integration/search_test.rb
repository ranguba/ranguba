# coding: utf-8
require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  ENTRIES_PER_PAGE = 10

  def setup
    setup_database
    @types = []
    @categories = []
    @entries_count = 0
    @db_source.each do |key, value|
      @types << value[:type]
      @categories << value[:category]
      @entries_count += 1
    end
    @types = @types.uniq.sort
    @categories = @categories.uniq.sort
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
                 :topic_path => [["query", "HTML"]],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"

    assert_visit "/search?search_request[type]=html&search_request[query]=HTML",
                 "/search/type/html/query/HTML"
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["type", "html"], ["query", "HTML"]],
                 :drilldown => {:category => ["test"]},
                 :pagination => "1/1"

    assert_visit "/search?search_request[query]=HTML&search_request[base_params]=type%2Fhtml",
                 "/search/type/html/query/HTML"
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["type", "html"], ["query", "HTML"]],
                 :drilldown => {:category => ["test"]},
                 :pagination => "1/1"

    assert_visit "/search?foobar"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
  end

  def test_unknown_parameter
    assert_visit "/search/query/entry/unknown/value"
    assert_error :message => I18n.t("invalid_request_message"),
                 :drilldown => {:type => @types,
                                :category => @categories}
  end

  def test_invalid_parameter
    assert_visit "/search/query"
    assert_error :message => I18n.t("invalid_request_message"),
                 :drilldown => {:type => @types,
                                :category => @categories}
  end

  def test_invalid_pagination
    assert_visit "/search/query/entry?page=9999"
    assert_error :message => I18n.t("not_found_message"),
                 :drilldown => {:type => @types,
                                :category => @categories}
  end

  def test_no_entry_found
    assert_visit "/search/"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
    fill_in "search_request_query", :with => "notfound"
    click_link_or_button "Search"

    assert_equal "/search/query/notfound", current_path
    assert_not_found
  end

  def test_one_entry_found
    assert_visit "/search/"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
    fill_in "search_request_query", :with => "HTML entry"
    click_link_or_button "Search"

    assert_equal "/search/query/HTML%20entry", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "HTML"], ["query", "entry"]],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"
  end

  def test_many_entries_found
    assert_visit "/search/"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
    within("div.search_form") do
      fill_in "query", :with => "entry"
      click_link_or_button "Search"
    end

    assert_equal "/search/query/entry", current_path
    assert_found :total_count => @entries_count,
                 :entries_count => ENTRIES_PER_PAGE,
                 :topic_path => [["query", "entry"]],
                 :drilldown => {:type => @types,
                                :category => @categories},
                 :pagination => "1/2"

    click_link_or_button"2"
    assert_equal "/search/query/entry", current_path
    assert_match /^\/search\/query\/entry?.*page=2/, current_full_path
    assert_found :total_count => @entries_count,
                 :entries_count => @entries_count - ENTRIES_PER_PAGE,
                 :topic_path => [["query", "entry"]],
                 :drilldown => {:type => @types,
                                :category => @categories},
                 :pagination => "2/2"
  end

  def test_topic_path_link
    test_drilldown_twice_with_multiple_queries

    # step back
    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-key='type']"+
                                "[@data-value='html']"+
                 "/child::a[@class='topic_path_link']").click
    assert_equal "/search/query/HTML%20entry/type/html", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "HTML"],
                                 ["query", "entry"],
                                 ["type", "html"]],
                 :drilldown => {:category => ["test"]},
                 :pagination => "1/1"

    # step back again
    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-key='query']"+
                                "[@data-value='entry']"+
                 "/child::a[@class='topic_path_link']").click
    assert_equal "/search/query/HTML%20entry", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "HTML"],
                                 ["query", "entry"]],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"
  end

  def test_topic_path_link_jump_to_top_level
    test_drilldown_twice_with_multiple_queries

    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-key='query']"+
                                "[@data-value='entry']"+
                 "/child::a[@class='topic_path_link']").click
    assert_equal "/search/query/HTML%20entry", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "HTML"],
                                 ["query", "entry"]],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"
  end

  def test_topic_path_reduce_link
    test_drilldown_twice_with_multiple_queries

    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-key='query']"+
                                "[@data-value='entry']"+
                 "/child::a[@class='topic_path_reduce_link']").click
    assert_equal "/search/query/HTML/type/html/category/test", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "HTML"],
                                 ["type", "html"],
                                 ["category", "test"]],
                 :pagination => "1/1"

    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-key='type']"+
                                "[@data-value='html']"+
                 "/child::a[@class='topic_path_reduce_link']").click
    assert_equal "/search/query/HTML/category/test", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "HTML"],
                                 ["category", "test"]],
                 :drilldown => {:type => ["html"]},
                 :pagination => "1/1"

    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-key='category']"+
                                "[@data-value='test']"+
                 "/child::a[@class='topic_path_reduce_link']").click
    assert_equal "/search/query/HTML", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "HTML"]],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"

    find(:xpath, "/descendant::li[@class='topic_path_item']"+
                                "[@data-key='query']"+
                                "[@data-value='HTML']"+
                 "/child::a[@class='topic_path_reduce_link']").click
    assert_equal "/search/", current_path
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}
  end

  def test_drilldown
    assert_visit "/search/"
    assert_search_form :drilldown => {:type => @types,
                                      :category => @categories}

    click_link_or_button "xml (1)"
    assert_equal "/search/type/xml", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["type", "xml"]],
                 :drilldown => {:category => ["test"]},
                 :pagination => "1/1"
  end

  def test_drilldown_after_search
    test_many_entries_found
    click_link_or_button"xml (1)"
    assert_equal "/search/query/entry/type/xml", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "entry"],
                                 ["type", "xml"]],
                 :drilldown => {:category => ["test"]},
                 :pagination => "1/1"
  end

  def test_drilldown_twice
    test_many_entries_found

    click_link_or_button"html (1)"
    assert_equal "/search/query/entry/type/html", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "entry"],
                                 ["type", "html"]],
                 :drilldown => {:category => @categories},
                 :pagination => "1/1"

    click_link_or_button"test (1)"
    assert_equal "/search/query/entry/type/html/category/test", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "entry"],
                                 ["type", "html"],
                                 ["category", "test"]],
                 :pagination => "1/1"
  end

  def test_drilldown_twice_with_multiple_queries
    test_one_entry_found
    click_link_or_button"html (1)"
    assert_equal "/search/query/HTML%20entry/type/html", current_path
    click_link_or_button"test (1)"
    assert_equal "/search/query/HTML%20entry/type/html/category/test", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "HTML"],
                                 ["query", "entry"],
                                 ["type", "html"],
                                 ["category", "test"]],
                 :pagination => "1/1"
  end

  def test_search_result_drilldown_after_search
    test_many_entries_found
    find(:xpath, "/descendant::li[@class='search_result_drilldown_category_item']/child::a").click
    assert_equal "/search/query/entry/category/test", current_path
    assert_found :total_count => @entries_count,
                 :entries_count => ENTRIES_PER_PAGE,
                 :topic_path => [["query", "entry"],
                                 ["category", "test"]],
                 :drilldown => {:type => @types},
                 :pagination => "1/2"
  end

  def test_search_after_drilldown
    test_drilldown

    fill_in "search_request_query", :with => "entry"
    click_link_or_button "Search"

    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["type", "xml"],
                                 ["query", "entry"]],
                 :drilldown => {:category => ["test"]},
                 :pagination => "1/1"
  end

  def test_search_with_multibytes_query
    assert_visit "/search/"
    fill_in "search_request_query", :with => "一太郎のドキュメント"
    click_link_or_button "Search"

    encoded = SearchRequest.encode_parameter("一太郎のドキュメント")
    assert_equal "/search/query/#{encoded}", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "一太郎のドキュメント"]],
                 :drilldown => {:type => ["jxw"],
                                :category => ["test"]},
                 :pagination => "1/1"
  end

  def test_search_with_query_including_slash
    assert_visit "/search/"
    fill_in "search_request_query", :with => "text/html"
    click_link_or_button "Search"

    assert_equal "/search/query/text%2Fhtml", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "text/html"]],
                 :drilldown => {:type => ["html"],
                                :category => ["test"]},
                 :pagination => "1/1"
  end

  def test_drilldown_after_search_including_slash
    test_search_with_query_including_slash

    find(:xpath, "/descendant::li[@class='search_result_drilldown_category_item']/child::a").click
    assert_equal "/search/query/text%2Fhtml/category/test", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "text/html"],
                                 ["category", "test"]],
                 :drilldown => {:type => ["html"]},
                 :pagination => "1/1"
  end

  def test_search_with_query_including_question
    assert_visit "/search/"
    fill_in "search_request_query", :with => "unknown type?"
    click_link_or_button "Search"

    assert_equal "/search/query/unknown%20type%3F", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "unknown"],
                                 ["query", "type?"]],
                 :drilldown => {:type => ["unknown"],
                                :category => ["test"]},
                 :pagination => "1/1"
  end

  def test_drilldown_after_search_including_question
    test_search_with_query_including_question

    find(:xpath, "/descendant::li[@class='search_result_drilldown_category_item']/child::a").click
    assert_equal "/search/query/unknown%20type%3F/category/test", current_path
    assert_found :total_count => 1,
                 :entries_count => 1,
                 :topic_path => [["query", "unknown"],
                                 ["query", "type?"],
                                 ["category", "test"]],
                 :drilldown => {:type => ["unknown"]},
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
    assert page.has_selector?(".search_form"), page.body
    assert page.has_no_selector?(".search_result"), page.body
    assert page.has_no_selector?(".search_result_error_message"), page.body
    assert_no_topic_path
    assert_no_pagination
    if options[:drilldown]
      assert_drilldown(options[:drilldown])
    else
      assert_no_drilldown
    end
  end

  def assert_found(options={})
    assert page.has_selector?(".search_form"), page.body
    assert page.has_selector?(".search_result"), page.body
    assert page.has_selector?(".search_result_entries"), page.body
    assert page.has_no_selector?(".search_result_error_message"), page.body

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
    assert page.has_selector?(".search_form"), page.body
    assert page.has_selector?(".search_result"), page.body
    assert page.has_no_selector?(".search_result_entries"), page.body
    assert page.has_selector?(".search_result_message"), page.body
    assert page.has_content?(I18n.t("search_result_not_found_message")), page.body
    assert_no_pagination
    if options[:drilldown]
      assert_drilldown(options[:drilldown])
    else
      assert_no_drilldown
    end
  end

  def assert_error(options={})
    assert page.has_selector?(".search_form"), page.body
    assert page.has_selector?(".search_result"), page.body
    assert page.has_no_selector?(".search_result_entries"), page.body
    assert page.has_selector?(".search_result_error_message"), page.body
    assert page.has_content?(options[:message]), page.body unless options[:message].nil?
    assert_no_topic_path
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
    entries = find(:xpath, "/descendant::ol[@class='search_result_entries']")
    assert_equal(count,
                 entries.all(:xpath, "./li[@class='search_result_entry']").size)
    assert_equal(count,
                 entries.all("li.search_result_drilldown_category_entry").size)
    assert_equal(count,
                 entries.all("li.search_result_drilldown_type_entry").size)
  end

  def assert_topic_path(items)
    topic_path = find("ol.topic_path")
    top_page_link, *topic_path_items = topic_path.all("li.topic_path_item")
    _ = top_page_link
    item_data_attributes = topic_path_items.collect do |item|
      [item["data-key"], item["data-value"]]
    end
    assert_equal(items, item_data_attributes)
  end

  def assert_no_topic_path
    assert page.has_no_selector?(".topic_path"), page.body
  end

  def assert_pagination(pagination_label)
    current, total = pagination_label.split("/")

    pagination = find(".pagination")
    assert_equal(current, pagination.find(".current").text)
  end

  def assert_no_pagination
    assert page.has_no_selector?(".pagination"), page.body
    assert page.has_no_selector?("#pagination_top"), page.body
    assert page.has_no_selector?("#pagination_bottom"), page.body
  end

  def assert_drilldown(groups)
    groups_ul = find("ul.drilldown_groups")
    actual_groups = {}
    groups_ul.all("li.drilldown_group").collect do |group|
      key = group["data-key"].to_sym
      actual_groups[key] ||= []
      group.all("li.drilldown_entry").each do |entry|
        actual_groups[entry["data-key"].to_sym] << entry["data-value"]
      end
      actual_groups[key].sort!
    end
    assert_equal(groups, actual_groups)
  end

  def assert_no_drilldown
    assert page.has_no_selector?(".drilldown_groups"), page.body
  end
end
