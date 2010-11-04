class DrilldownItem < SearchRequest
  attr_accessor :param
  attr_accessor :value
  attr_accessor :count

  def initialize(options={})
    super
    send("#{param.to_s}=", value) unless param.blank?
  end

  def label
    Ranguba::Customize.get(param.to_s, value)
  end

  def label_with_count
    I18n.t("drilldown_item_label", :label => label, :count => count)
  end
end

