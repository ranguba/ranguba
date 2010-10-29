class DrilldownItem
  attr_accessor :param
  attr_accessor :value
  attr_accessor :count

  def initialize(options={})
    options.each do |key, value|
      send("#{key}=", value)
    end
  end

  def label
    I18n.t("column_#{param}_label_#{value}")
  end

  def label_with_count
    I18n.t("drilldown_item_label", :label => label, :count => count)
  end

  def path(options={})
    SearchRequest.path(:base_path => options[:base_path],
                       :options => to_hash(options[:options]))
  end

  def to_hash(options={})
    hash = {}.merge(options)
    hash[param.to_sym] = value
    hash
  end
end

