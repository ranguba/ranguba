class Ranguba::TopicPathItem
  attr_reader :key, :value
  attr_accessor :value_label
  def initialize(key, value)
    @key = key
    @key = @key.to_s if @key
    @value = value
    @value_label = nil
  end

  def valid?
    not @value.blank?
  end

  def query_item?
    @key == "query"
  end

  def label
    I18n.t("topic_path_item_label",
           :type => type,
           :value => value_label)
  end

  def path
    "#{CGI.escape(key)}/#{CGI.escape(value)}"
  end

  def reduce_title
    I18n.t(:"topic_path_reduce_#{@key}_item_label",
           :type => type,
           :value => value_label,
           :default => :"topic_path_reduce_item_label")
  end

  def type
    I18n.t(:"column_#{key}_name",
           :key => @key,
           :default => [:"column_name", @key])
  end

  def value_label
    @value_label ||= I18n.t(@value, :scope => @key) || @value
  end

end
