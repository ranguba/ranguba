class DrilldownEntry < SearchRequest
  attr_accessor :key
  attr_accessor :value
  attr_accessor :count

  def initialize(options={})
    super
    self.key = options[:key]
    self.value = options[:value]
    self.count = options[:count] || 0
  end

  def value=(value)
    send("#{key}=", value) unless key.nil?
    @value = value
  end

  def label
    Ranguba::Customize.get(key.to_s, value)
  end

  def label_with_count
    I18n.t("drilldown_entry_label", :label => label, :count => count)
  end
end

