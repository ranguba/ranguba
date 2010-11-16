require "racknga/will_paginate"

class Ranguba::Entry < ActiveGroonga::Base
  DEFAULT_SUMMARY_SIZE = 140

  table_name("entries")
  reference_class("encoding", Ranguba::Encoding)
  reference_class("mime_type", Ranguba::MimeType)
  reference_class("type", Ranguba::Type)
  reference_class("author", Ranguba::Author)
  reference_class("category", Ranguba::Category)
  reference_class("extension", Ranguba::Extension)

  def title
    _title = super
    _title = url if _title.blank?
    _title
  end

  def url
    key
  end

  def category
    _category = super
    _category = _category.key if _category
    _category
  end

  def type
    _type = super
    _type = _type.key if _type
    _type
  end

  def drilldown_items
    @drilldown_items ||= compute_drilldown_items
  end

  def summary(expression, options={})
    summary = summary_by_query(expression, options)
    summary = summary_by_head(options) if summary.blank?
    summary
  end

  def summary_by_head(options={})
    options = normalize_summary_options(options)
    summary = body
    if !summary.blank? && summary.size > options[:size]
      summary = summary[0..(options[:size]-1)] + options[:separator]
    end
    summary
  end

  def summary_by_query(expression, options={})
    return "" unless expression

    options = normalize_summary_options(options)

    highlight_tags = options[:highlight].split("%S")

    snippet_options = {
      :normalize => true,
      :width => options[:size],
      :html_escape => options[:html_escape]
    }

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

  private
  def compute_drilldown_items
    items = []
    SearchRequest::KEYS.each do |key|
      next if key == :query || send(key).blank?
    items << DrilldownItem.new(:param => key,
                               :value => send(key))
    end
    items
  end

  def normalize_summary_options(options={})
    options[:size] ||= DEFAULT_SUMMARY_SIZE
    options[:highlight] ||= "*%S*"
    options[:separator] ||= "..."
    options[:part] ||= "%S"
    options
  end
end

