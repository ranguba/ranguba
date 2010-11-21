class DrilldownEntry < SearchRequest
  attr_accessor :param
  attr_accessor :value
  attr_accessor :count

  def initialize(options={})
    super
    self.param = options[:param]
    self.value = options[:value]
    self.count = options[:count] || 0
  end

  def value=(value)
    send("#{param.to_s}=", value) unless param.nil?
    @value = value
  end

  def label
    Ranguba::Customize.get(param.to_s, value)
  end

  def label_with_count
    I18n.t("drilldown_entry_label", :label => label, :count => count)
  end
end

