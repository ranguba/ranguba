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
    base = options[:base_path].sub(/\/$/, "")
    search_request = SearchRequest.new(to_hash(options[:base_options])).to_s
    [base, search_request].join(SearchRequest::DELIMITER)
  end

  def to_hash(base_options={})
    hash = {}.merge(base_options)
    hash[param.to_sym] = value
    hash
  end
end

