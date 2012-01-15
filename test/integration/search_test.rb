# coding: utf-8
require 'test_helper'

class SearchTest < ActionDispatch::IntegrationTest
  ENTRIES_PER_PAGE = 10

  def setup
    setup_database
    @types = []
    @categories = []
    @entries_count = 0
    @test_category_entries_count = 0
    @db_source.each do |key, value|
      @types << value[:type]
      @categories << value[:category]
      @entries_count += 1
      @test_category_entries_count += 1 if value[:category] == "test"
    end
    @types = @types.uniq.sort
    @categories = @categories.uniq.sort
  end

  def teardown
    teardown_database
  end

  class NoConditionTest < self
    def test_with_trailing_slash
      assert_visit "/search/"
      assert_initial_view
    end

    def test_without_trailing_slash
      assert_visit "/search"
      assert_initial_view
    end

    def test_unknown_query
      assert_visit "/search?unknown"
      assert_initial_view
    end
  end

  class ValidConditionTest < self
    def test_query
      assert_visit("/search/query/HTML")
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "HTML"]],
                   :drilldown => {:type => ["html"],
                                  :category => ["test"]},
                   :pagination => "1/1")
    end

    def test_query_string
      visit("/search?search_request[type]=html&search_request[query]=HTML")
      assert_equal("/search/type/html/query/HTML", current_full_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["type", "html"], ["query", "HTML"]],
                   :drilldown => {:category => ["test"]},
                   :pagination => "1/1")
    end
  end

  class InvalidConditionTest < self
    def test_unknown_parameter
      assert_visit("/search/query/entry/unknown/value")
      assert_error(:message => I18n.t("invalid_request_message"),
                   :topic_path => [["query", "entry"]])
    end

    def test_no_value
      assert_visit("/search/query")
      assert_error(:message => I18n.t("invalid_request_message"),
                   :topic_path => [])
    end
  end

  class PaginationTest < self
    def test_too_large
      assert_visit("/search/query/entry?page=9999")
      assert_error(:message => I18n.t("not_found_message"),
                   :topic_path => [["query", "entry"]])
    end

    def test_one_page
      assert_visit("/search/")
      search("HTML entry")
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "HTML"], ["query", "entry"]],
                   :drilldown => {:type => ["html"],
                                  :category => ["test"]},
                   :pagination => "1/1")
    end

    def test_two_pages
      assert_visit("/search/")
      within("div.search_form") do
        fill_in("query", :with => "entry")
        click_link_or_button("Search")
      end

      assert_equal("/search/query/entry", current_path)
      assert_found(:total_count => @entries_count,
                   :entries_count => ENTRIES_PER_PAGE,
                   :topic_path => [["query", "entry"]],
                   :drilldown => {:type => @types,
                                  :category => @categories},
                   :pagination => "1/2")

      click_link_or_button("2")
      assert_equal("/search/query/entry", current_path)
      assert_match(/^\/search\/query\/entry?.*page=2/, current_full_path)
      assert_found(:total_count => @entries_count,
                   :entries_count => @entries_count - ENTRIES_PER_PAGE,
                   :topic_path => [["query", "entry"]],
                   :drilldown => {:type => @types,
                                  :category => @categories},
                   :pagination => "2/2")
    end
  end

  class QueryTest < self
    def test_not_found
      assert_visit("/search/")
      within("div.search_form") do
        fill_in("query", :with => "nonexistent")
        click_link_or_button("Search")
      end

      assert_equal("/search/query/nonexistent", current_path)
      assert_not_found
    end

    def test_drilldown
      assert_visit("/search/type/html")

      within("div.search_form") do
        fill_in "query", :with => "entry"
        click_link_or_button "Search"
      end

      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["type", "html"],
                                   ["query", "entry"]],
                   :drilldown => {:category => ["test"]},
                   :pagination => "1/1")
    end

    def test_multi_bytes
      assert_visit("/search/")

      within("div.search_form") do
        fill_in "query", :with => "一太郎のドキュメント"
        click_link_or_button "Search"
      end

      encoded = CGI.escape("一太郎のドキュメント")
      assert_equal("/search/query/#{encoded}", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "一太郎のドキュメント"]],
                   :drilldown => {:type => ["jxw"],
                                  :category => ["test"]},
                   :pagination => "1/1")
    end

    def test_slash
      assert_visit("/search/")
      within("div.search_form") do
        fill_in("query", :with => "text/html")
        click_link_or_button("Search")
      end

      assert_equal("/search/query/text%2Fhtml", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "text/html"]],
                   :drilldown => {:type => ["html"],
                                  :category => ["test"]},
                   :pagination => "1/1")
    end

    def test_question
      assert_visit("/search/")
      within("div.search_form") do
        fill_in("query", :with => "unknown type?")
        click_link_or_button("Search")
      end

      assert_equal("/search/query/unknown+type%3F", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "unknown"],
                                   ["query", "type?"]],
                   :drilldown => {:type => ["unknown"],
                                  :category => ["test"]},
                   :pagination => "1/1")
    end
  end

  class TopicPathTest < self
    def test_jump_to_top_level
      assert_visit("/search/query/HTML+entry/type/html")

      within(".topic_path") do
        find(".topic_path_link").click
      end
      assert_equal("/search", current_path)
      assert_initial_view
    end

    def test_step_by_step
      assert_visit("/search/query/HTML+entry/type/html/category/test")

      within(".topic_path") do
        assert_all(".topic_path_reduce_link").last.click
      end
      assert_equal("/search/query/HTML+entry/type/html", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "HTML"],
                                   ["query", "entry"],
                                   ["type", "html"]],
                   :drilldown => {:category => ["test"]},
                   :pagination => "1/1")

      within(".topic_path") do
        assert_all(".topic_path_reduce_link").last.click
      end
      assert_equal("/search/query/HTML+entry", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "HTML"],
                                   ["query", "entry"]],
                   :drilldown => {:type => ["html"],
                                  :category => ["test"]},
                   :pagination => "1/1")

      within(".topic_path") do
        assert_all(".topic_path_reduce_link").last.click
      end
      assert_equal("/search/query/HTML", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "HTML"]],
                   :drilldown => {:type => ["html"],
                                  :category => ["test"]},
                   :pagination => "1/1")

      within(".topic_path") do
        assert_all(".topic_path_reduce_link").last.click
      end
      assert_equal("/search", current_path)
      assert_initial_view
    end

    def test_delete_query_word
      assert_visit("/search/query/HTML+entry/type/html")

      within(".topic_path") do
        query_items = assert_all(".topic_path_item[data-key=\"query\"]")
        query_items.last.find(".topic_path_reduce_link").click
      end
      assert_equal("/search/query/HTML/type/html", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "HTML"],
                                   ["type", "html"]],
                   :drilldown => {:category => ["test"]},
                   :pagination => "1/1")
    end
  end

  class DrilldownTest < self
    def test_initial_view
      assert_visit("/search/")

      drilldown("xml (1)")
      assert_equal("/search/type/xml", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["type", "xml"]],
                   :drilldown => {:category => ["test"]},
                   :pagination => "1/1")
    end

    def test_after_search
      assert_visit("/search/")
      search("entry")

      drilldown("xml (1)")
      assert_equal("/search/query/entry/type/xml", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "entry"],
                                   ["type", "xml"]],
                   :drilldown => {:category => ["test"]},
                   :pagination => "1/1")
    end

    def test_twice
      assert_visit("/search/")
      search("entry")

      drilldown("HTML (1)")
      assert_equal("/search/query/entry/type/html", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "entry"],
                                   ["type", "html"]],
                   :drilldown => {:category => ["test"]},
                   :pagination => "1/1")

      drilldown("test (1)")
      assert_equal("/search/query/entry/type/html/category/test", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "entry"],
                                   ["type", "html"],
                                   ["category", "test"]],
                   :pagination => "1/1")
    end

    def test_multiple_queries
      assert_visit("/search/")
      search("HTML entry")

      drilldown("HTML (1)")
      assert_equal("/search/query/HTML+entry/type/html", current_path)

      drilldown("test (1)")
      assert_equal("/search/query/HTML+entry/type/html/category/test",
                   current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "HTML"],
                                   ["query", "entry"],
                                   ["type", "html"],
                                   ["category", "test"]],
                   :pagination => "1/1")
    end

    def test_slash_in_context
      assert_visit("/search/query/text%2Fhtml")

      drilldown("test (1)")
      assert_equal("/search/query/text%2Fhtml/category/test", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "text/html"],
                                   ["category", "test"]],
                   :drilldown => {:type => ["html"]},
                   :pagination => "1/1")
    end

    def test_drilldown_after_search_including_question
      assert_visit("/search/")
      search("unknown type?")

      drilldown("test (1)")
      assert_equal("/search/query/unknown+type%3F/category/test", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "unknown"],
                                   ["query", "type?"],
                                   ["category", "test"]],
                   :drilldown => {:type => ["unknown"]},
                   :pagination => "1/1")
    end

    private
    def drilldown(item_label)
      within(".search_request") do
        within(".drilldown_groups") do
          click_link_or_button(item_label)
        end
      end
    end
  end

  private
  def current_full_path
    current_url.sub(/^\w+:\/\/[^\/]+/, "")
  end

  def search(query)
    within("div.search_form") do
      fill_in("query", :with => query)
      click_link_or_button("Search")
    end

    assert_equal("/search/query/#{CGI.escape(query)}", current_path)
  end

  def assert_visit(path, expected_path=nil)
    visit path
    assert_equal (expected_path || path), current_full_path
  end

  def assert_have_search_form
    within(".search_request") do
      find(".search_form")
    end
  end

  def assert_no_search_result
    within(".content") do
      assert_not_find(".search_result")
    end
  end

  def assert_initial_view
    assert_have_search_form
    assert_no_search_result
    assert_no_topic_path
    assert_no_pagination
    assert_drilldown(:type => @types, :category => @categories)
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
    if options[:topic_path]
      assert_topic_path(options[:topic_path])
    else
      assert_no_topic_path
    end
    assert_no_pagination
    if options[:drilldown]
      assert_drilldown(options[:drilldown])
    else
      assert_no_drilldown
    end
  end

  def assert_total_count(count)
    within("div.search_result") do
      result_count = find(".search_result_count")
      assert_equal(I18n.t("search_result_count", :count => count),
                   result_count.text.gsub(/\([\d.]+ sec\)/m, "").strip)
    end
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
    assert_not_find(".topic_path")
  end

  def assert_pagination(pagination_label)
    current, total = pagination_label.split("/")

    pagination = find(".pagination")
    assert_equal(current, pagination.find(".current").text)
  end

  def assert_no_pagination
    assert_not_find(".pagination")
    assert_not_find("#pagination_top")
    assert_not_find("#pagination_bottom")
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
