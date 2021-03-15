class Ranguba::DrilldownEntry
  attr_reader :key
  attr_reader :value
  attr_reader :count

  def initialize(key:, value:, count: 0)
    @key = key
    @value = value
    @count = count
  end

  def label
    I18n.t(value, :scope => key)
  end

  def label_with_count
    I18n.t("drilldown_entry_label", :label => label, :count => count)
  end

  def path
    "#{CGI.escape(key.to_s)}/#{CGI.escape(value.to_s)}"
  end

  def query_item?
    false
  end
end
