class Ranguba::Entry < ApplicationGroongaRecord
  DEFAULT_SUMMARY_SIZE = 140

  # reference_class("encoding", Ranguba::Encoding)
  # reference_class("mime_type", Ranguba::MimeType)
  # reference_class("type", Ranguba::Type)
  # reference_class("author", Ranguba::Author)
  # reference_class("category", Ranguba::Category)
  # reference_class("extension", Ranguba::Extension)

  before_validation do
    if body.blank?
      self.content_length = 0
    else
      self.content_length = body.bytesize
    end
  end

  def label
    if respond_to?(:highlighted_title)
      return highlighted_title.html_safe
    end
    _title = title
    if _title and !_title.valid_encoding?
      logger.warn("#{Time.now} [encoding][invalid][title] " +
                  "key: #{key}: #{_title.inspect}")
      _title = nil
    end
    return _title unless _title.blank?
    _url = url
    if _url and !_url.valid_encoding?
      logger.warn("#{Time.now} [encoding][invalid][title][fallback][url] " +
                  "key: #{key}: <#{_url.inspect}>")
      _url = ""
    end
    _url
  end

  def url
    _key
  end

  def summary
    return "" unless respond_to?(:snippets)
    snippets.join(I18n.t("search_result_summary_ellipses")).html_safe
  end

  def drilldown_entries
    @drilldown_entries ||= compute_drilldown_entries
  end

  private
  def compute_drilldown_entries
    entries = []
    Ranguba::SearchRequest::KEYS.each do |key|
      next if key == :query
      value = public_send(key)
      next if value.blank?
      entries << Ranguba::DrilldownEntry.new(key: key, value: value)
    end
    entries
  end
end

