class DrilldownItem < SearchRequest
  attr_accessor :param
  attr_accessor :value
  attr_accessor :count

  def initialize(options={})
    super
    self.param = options[:param] unless options[:param].nil?
    self.value = options[:value] unless options[:value].nil?
    self.count = options[:count] || 0
  end

  def value=(val)
    send("#{param.to_s}=", val) unless param.nil?
    @value = val
  end

  def label
    Ranguba::Customize.get(param.to_s, value)
  end

  def label_with_count
    I18n.t("drilldown_item_label", :label => label, :count => count)
  end
end

