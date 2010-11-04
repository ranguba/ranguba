require "racknga/will_paginate"

class Entry
  SUMMARY_MAX_SIZE = 30
  DEFAULT_PAGINATION_PER_PAGE = 10
  DEFAULT_SUMMARY_SIZE = 140

  attr_accessor :title
  attr_accessor :url
  attr_accessor :category
  attr_accessor :type
  attr_accessor :body
  attr_accessor :expression

  class << self
  
    def table
      @@table ||= Groonga["Entries"]
    end

    def search(options={})
      results = []
      drilldown_results = {}

      conditions = conditions_from_request(options)
      records = table.select do |record|
        conditions.collect do |condition|
          condition.call(record)
        end.flatten
      end
      expression = records.expression

      drilldown_results = drilldown_groups(options.merge(:records => records))

      current = options[:page]
      if current.blank?
        current = 1
      elsif current.is_a?(String)
        current = current.to_i
      end

      records = records.paginate([["_score", :descending],
                                  [".title", :ascending]],
                                 :page => current,
                                 :size => (options[:per_page] || DEFAULT_PAGINATION_PER_PAGE))
      records.each do |record|
        url = record.key.key.to_s
        title = record[".title"].to_s
        next unless title.valid_encoding?
        results << new(:title => title.blank? ? url : title,
                       :url => url,
                       :category => record[".category"] ? record[".category"].key : nil,
                       :type => record[".type"] ? record[".type"].key : nil,
                       :body => record[".body"].to_s,
                       :expression => expression)
      end

      {:entries => results,
       :raw_entries => records,
       :drilldown_groups => drilldown_results}
    end

    def add(url, attributes)
      table.add(url, attributes)
    end

    private
    def conditions_from_request(options)
      conditions = []
      unless options[:query].blank?
        conditions << Proc.new do |record|
          options[:query].split.collect do |term|
            (record.key.key =~ term) |
            (record[".title"] =~ term) |
            (record[".body"] =~ term)
          end.inject do |match_conditions, match_condition|
            match_conditions & match_condition
          end
        end
      end
      unless options[:category].blank?
        conditions << Proc.new do |record|
          record[".category"] == options[:category]
        end
      end
      unless options[:type].blank?
        conditions << Proc.new do |record|
          record[".type"] == options[:type]
        end
      end
      conditions
    end

    def drilldown_groups(options={})
      result = {}
      [:category, :type].each do |column|
        next unless options[column].nil?
        group = drilldown_group(:records => options[:records],
                                :drilldown => column,
                                :label => "_key",
                                :search_request => options[:search_request])
        result[I18n.t("column_#{column}_name")] = group unless group.empty?
      end
      result
    end

    def drilldown_group(options={})
      result = options[:records].group(options[:drilldown].to_s)
      result = result.sort([["_nsubrecs", :descending]], :limit => 10)
      result.collect do |record|
        key = options[:drilldown]
        value = record[options[:label]].to_s
        DrilldownItem.new(:param => key,
                          :value => value,
                          :count => record.n_sub_records,
                          :base_params => options[:search_request] ? options[:search_request].to_s : nil)
      end
    end

  end

  def initialize(options={})
    options.each do |key, value|
      send("#{key}=", value)
    end
  end

  def summary(options={})
    summary = summary_by_query(options)
    summary = summary_by_head(options) if summary.blank?
    summary
  end

  private
  def summary_by_head(options={})
    options = normalize_summary_options(options)
    summary = body
    if !summary.blank? && summary.size > options[:size]
      summary = summary[0..options[:size]] + options[:separator]
    end
    summary
  end

  def summary_by_query(options={})
    options = normalize_summary_options(options)

    highlight_tags = options[:highlight].split("%S")

    snippet_options = {:normalize => true,
                       :width => options[:size],
                       :html_escape => options[:html_escape]}

    snippet = expression.snippet(highlight_tags, snippet_options)
    snippet ||= Groonga::Snippet.new(snippet_options)

    summarized = ""
    if snippet && !body.blank?
      snippets = snippet.execute(body)
      unless snippets.empty?
        snippets = snippets.collect do |snippet|
          options[:part].sub("%S", "#{options[:separator]}#{snippet}#{options[:separator]}")
        end
        summarized = snippets.join("")
      end
    end
    summarized
  end

  def normalize_summary_options(options={})
    options[:size] ||= DEFAULT_SUMMARY_SIZE
    options[:highlight] ||= "*%S*"
    options[:separator] ||= "..."
    options[:part] ||= "%S"
    options
  end
end

