class TopicPathItem
  attr_reader :key, :value
  attr_accessor :value_label
  def initialize(key, value, items)
    @key = key
    @key = @key.to_s if @key
    @value = value
    @value_label = nil
    @items = items
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

  def title
    labels = forward_items.collect(&:label)
    labels << label
    labels.join(I18n.t("search_conditions_delimiter"))
  end

  def path
    _path = current_path
    _path << "../#{CGI.escape(current_query)}/" if query_item?
    _path
  end

  def reduce_title
    I18n.t(:"topic_path_reduce_#{@key}_item_label",
           :type => type,
           :value => value_label,
           :default => :"topic_path_reduce_item_label")
  end

  def reduce_path
    reduced_path = parent_path
    _query_items = query_items
    reduce_query_items(backward_items).each do |item|
      if query_item? and item.query_item?
        value = (_query_items - [self]).collect(&:value_label).join(" ")
      else
        value = item.value
      end
      reduced_path << "#{CGI.escape(item.key)}/#{CGI.escape(value)}/"
    end
    reduced_path
  end

  def type
    I18n.t(:"column_#{key}_name",
           :key => @key,
           :default => [:"column_name", @key])
  end

  def value_label
    @value_label ||= Ranguba::Customize.get(@key, @value) || @value
  end

  def forward_items
    @items[0...(@items.index(self))]
  end

  def backward_items
    @items[(@items.index(self) + 1)..-1]
  end

  private
  def current_path
    previous_item = forward_items.last
    n_backward_items = 0
    backward_items.each do |item|
      if previous_item.nil? or !item.query_item?
        n_backward_items += 1
      end
      previous_item = item
    end
    n_backward_items -= 1 if query_item? and @items.index(self).zero?
    "../../" * n_backward_items
  end

  def parent_path
    "#{current_path}../../"
  end

  def current_query
    return nil unless query_item?
    forward_query_items = [self]
    forward_items.reverse.each do |item|
      break unless item.query_item?
      forward_query_items << item
    end
    forward_query_items.reverse.collect(&:value_label).join(" ")
  end

  def query_items
    @items.find_all(&:query_item?)
  end

  def reduce_query_items(items)
    reduced_items = []
    last_query_item = query_item? ? self : nil
    items.each do |item|
      if item.query_item?
        last_query_item = item
      else
        reduced_items << last_query_item if last_query_item
        last_query_item = nil
        reduced_items << item
      end
    end
    reduced_items << last_query_item if last_query_item
    reduced_items
  end
end
