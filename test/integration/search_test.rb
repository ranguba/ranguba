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
      visit("/search/")
      assert_initial_view
    end

    def test_without_trailing_slash
      visit("/search")
      assert_initial_view
    end

    def test_unknown_query
      visit("/search?unknown")
      assert_initial_view
    end
  end

  class ValidConditionTest < self
    def test_query
      visit("/search/query/HTML")
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
      visit("/search/query/entry/unknown/value")
      assert_error(:message => I18n.t("invalid_request_message"),
                   :topic_path => [["query", "entry"]])
    end

    def test_no_value
      visit("/search/query")
      assert_error(:message => I18n.t("invalid_request_message"),
                   :topic_path => [])
    end
  end

  class PaginationTest < self
    def test_too_large
      visit("/search/query/entry?page=9999")
      assert_error(:message => I18n.t("not_found_message"),
                   :topic_path => [["query", "entry"]])
    end

    def test_one_page
      visit("/search/")
      search("HTML entry")
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "HTML"], ["query", "entry"]],
                   :drilldown => {:type => ["html"],
                                  :category => ["test"]},
                   :pagination => "1/1")
    end

    def test_two_pages
      visit("/search/")
      search("entry")
      assert_found(:total_count => @entries_count,
                   :entries_count => ENTRIES_PER_PAGE,
                   :topic_path => [["query", "entry"]],
                   :drilldown => {:type => @types,
                                  :category => @categories},
                   :pagination => "1/2")

      within(".search_result") do
        within(".pagination") do
          click_link("2")
        end
      end
      assert_equal("/search/query/entry?page=2", current_full_path)
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
      visit("/search/")
      search("nonexistent")
      assert_equal("/search/query/nonexistent", current_path)
      assert_not_found
    end

    def test_drilldown
      visit("/search/type/html")
      search("entry")
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["type", "html"],
                                   ["query", "entry"]],
                   :drilldown => {:category => ["test"]},
                   :pagination => "1/1")
    end

    def test_multi_bytes
      visit("/search/")
      search("一太郎のドキュメント")
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "一太郎のドキュメント"]],
                   :drilldown => {:type => ["jxw"],
                                  :category => ["test"]},
                   :pagination => "1/1")
    end

    def test_slash
      visit("/search/")
      search("text/html")
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["query", "text/html"]],
                   :drilldown => {:type => ["html"],
                                  :category => ["test"]},
                   :pagination => "1/1")
    end

    def test_question
      visit("/search/")
      search("unknown type?")
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
      visit("/search/query/HTML+entry/type/html")

      within(".topic_path") do
        find(".topic_path_link").click
      end
      assert_equal("/search", current_path)
      assert_initial_view
    end

    def test_step_by_step
      visit("/search/query/HTML+entry/type/html/category/test")

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
      visit("/search/query/HTML+entry/type/html")

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
      visit("/search/")

      drilldown("xml (1)")
      assert_equal("/search/type/xml", current_path)
      assert_found(:total_count => 1,
                   :entries_count => 1,
                   :topic_path => [["type", "xml"]],
                   :drilldown => {:category => ["test"]},
                   :pagination => "1/1")
    end

    def test_after_search
      visit("/search/")
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
      visit("/search/")
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
      visit("/search/")
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
      visit("/search/query/text%2Fhtml")

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
      visit("/search/")
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
    URI.parse(current_url).route_from(current_host).to_s
  end

  def search(query)
    before_path = current_path.gsub(/\/\z/, "")

    within("div.search_form") do
      fill_in("query", :with => query)
      click_link_or_button("Search")
    end

    assert_equal("#{before_path}/query/#{CGI.escape(query)}", current_path)
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
    within(".search_request") do
      find(".search_form")
    end

    within(".search_result") do
      find(".search_result_entries")
      assert_not_find(".search_result_error_message")
    end

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
    within(".search_request") do
      find(".search_form")
    end

    within(".search_result") do
      assert_not_find(".search_result_entries")
      within(".search_result_message") do
        assert_equal(I18n.t("search_result_not_found_message"), text)
      end
    end

    assert_no_pagination
    if options[:drilldown]
      assert_drilldown(options[:drilldown])
    else
      assert_no_drilldown
    end
  end

  def assert_error(options={})
    within(".search_request") do
      find(".search_form")
    end

    within(".search_result") do
      assert_not_find(".search_result_entries")
      within(".search_result_error_message") do
        assert_equal(options[:message], text) unless options[:message].nil?
      end
    end

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
      within(".search_result_count") do
        assert_equal(I18n.t("search_result_count", :count => count),
                     text.gsub(/\([\d.]+ sec\)/m, "").strip)
      end
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
