class DrilldownEntry
  attr_accessor :key
  attr_accessor :value
  attr_accessor :count

  def initialize(options={})
    self.key = options[:key]
    self.value = options[:value]
    self.count = options[:count] || 0
  end

  def label
    I18n.t(value, :scope => key)
  end

  def label_with_count
    I18n.t("drilldown_entry_label", :label => label, :count => count)
  end

  def path
    "#{CGI.escape(key.to_s)}/#{CGI.escape(value)}/"
  end
end
