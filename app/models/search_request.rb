class SearchRequest
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :query
  attr_accessor :category
  attr_accessor :type

  KEYS = ["query", "category", "type"]
  DELIMITER = "/"

  validate :validate_string

  class << self
    def path(options={})
      base = options[:base_path].sub(/\/$/, "")
      search_request = new(options[:options]).to_s
      [base, search_request].join(DELIMITER)
    end

    def encode_parameter(input)
      URI.encode(input, /[^-_.!~*'()a-zA-Z\d?@]/n) # same to encodeURIComponent (in JavaScript)
    end
  end

  def initialize(options={})
    options.each do |key, value|
      send("#{key}=", value)
    end
  end

  def query=(value)
    @string = nil
    @query = value
  end

  def category=(value)
    @string = nil
    @category = value
  end

  def type=(value)
    @string = nil
    @type = value
  end

  def clear
    @string = nil
    @query = nil
    @category = nil
    @type = nil
  end

  def parse(query_string="")
    clear

    query_string = (query_string || "").gsub(/^\/+|\/+$/, "")
    return if query_string.blank?

    parts = query_string.split(DELIMITER)
    i = 0
    while i < parts.size
      key = parts[i]
      value = parts[i+1]
      send("#{key}=", URI.decode(value)) if KEYS.include?(key) && !value.blank?
      i += 2
    end

    @string = query_string
  end

  def to_s
    return @string unless @string.nil?

    path_components = []
    KEYS.each do |key|
      value = send(key)
      unless value.blank?
        path_components << key
        path_components << self.class.encode_parameter(value.to_s)
      end
    end
    path_components.join("/")
  end

  def path(options={})
    options[:options] ||= {}
    options[:options] = to_hash.merge(options[:options])
    if options[:without]
      options[:options].delete(options[:without])
    end
    self.class.path(options)
  end

  def to_readable_string
    conditions = []
    conditions << query unless query.blank?
    unless category.blank?
      conditions << I18n.t("topic_path_item_label",
                           :type => I18n.t("column_category_name"),
                           :label => I18n.t("column_category_label_#{category}"))
    end
    unless type.blank?
      conditions << I18n.t("topic_path_item_label",
                           :type => I18n.t("column_type_name"),
                           :label => I18n.t("column_type_label_#{type}"))
    end
    conditions.join(I18n.t("search_conditions_delimiter"))
  end

  def topic_path_items(options={})
    items = []
    options[:options] ||= {}

    unless query.nil?
      terms = query.split
      terms.each do |term|
        opt = options.merge(
                :options => options[:options].merge(
                  :query => (terms - [term]).join(" ")
                )
              )
        items << {:label => term,
                  :path => path(opt),
                  :param => "query"}
      end
    end

    KEYS.each do |key|
      next if ["query"].include?(key)
      value = send(key)
      unless value.nil?
        items << {:label => I18n.t("topic_path_item_label",
                                   :type => I18n.t("column_#{key}_name"),
                                   :label => value),
                  :title => I18n.t("topic_path_reduce_item_label",
                                   :type => I18n.t("column_#{key}_name"),
                                   :label => value),
                  :path => path(options.merge(:without => key.to_sym)),
                  :param => key}
      end
    end

    items
  end

  def to_hash
    hash = {}
    KEYS.each do |key|
      value = send(key)
      hash[key.to_sym] = value unless value.blank?
    end
    hash
  end

  def attributes
    to_hash
  end

  def empty?
    (query || category || type) ? false : true
  end

  def persisted?
    false
  end

  def respond_to?(name, priv=false)
    true
  end

  private
  def validate_string
    return if @string.nil?
    parts = @string.split("/")
    i = 0
    while i < parts.size
      key = parts[i]
      value = parts[i+1]
      case
      when KEYS.include?(key)
        if value.blank?
          errors.add(key.to_sym, I18n.t("search_request_blank_value",
                                        :key => key,
                                        :value => value))
        end
      when value.blank?
        errors.add(key.to_sym, I18n.t("search_request_invalid_key_blank_value",
                                      :key => key))
      else
        errors.add(key.to_sym, I18n.t("search_request_invalid_key",
                                      :key => key,
                                      :value => value))
      end
      i += 2
    end
  end
end

