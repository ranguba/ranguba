class SearchRequest
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :query
  attr_accessor :category
  attr_accessor :type
  attr_accessor :base_params

  KEYS = ["query", "category", "type"]
  DELIMITER = "/"

  validate :validate_string

  class << self
    def path(options={})
      base = options[:base_path].sub(/\/$/, "")
      search_request_options = options[:path] || new(options[:options]).to_s
      [base, search_request_options].join(DELIMITER)
    end

    def encode_parameter(input)
      URI.encode(input, /[^-_.!~*'()a-zA-Z\d?@]/n) # same to encodeURIComponent (in JavaScript)
    end
  end

  def initialize(options={})
    clear
    parse(options[:base_params]) unless options[:base_params].blank?
    update(options)
  end

  def update(options={})
    options.each do |key, value|
      send("#{key}=", value) unless send(key) == value
    end
  end

  def query=(value)
    @query = value
    @ordered_keys = @ordered_keys - ["query"]
    @ordered_keys << "query"
  end

  def category=(value)
    @category = value
    @ordered_keys = @ordered_keys - ["category"]
    @ordered_keys << "category"
  end

  def type=(value)
    @type = value
    @ordered_keys = @ordered_keys - ["type"]
    @ordered_keys << "type"
  end

  def clear
    @string = nil
    @query = nil
    @category = nil
    @type = nil
    @ordered_keys = []
  end

  def ordered_keys(options={})
    options[:canonical] ? KEYS : (@ordered_keys + (KEYS - @ordered_keys))
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

  def to_s(options={})
    path_components = []
    ordered_keys(options).each do |key|
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

  def to_readable_string(options={})
    conditions = []

    conditions << query unless query.blank?

    ordered_keys(options).each do |key|
      next if key == "query"
      value = send(key)
      unless value.nil?
        value = Ranguba::Customize.get(key, value)
        type = I18n.t("column_#{key}_name")
        conditions << I18n.t("topic_path_item_label",
                             :type => type,
                             :label => value)
      end
    end

    conditions.join(I18n.t("search_conditions_delimiter"))
  end

  def topic_path_items(options={})
    items = []
    options[:options] ||= {}

    ordered_keys(options).each do |key|
      case key
      when "query"
        next if query.blank?
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
      else
        value = send(key)
        unless value.nil?
          value = Ranguba::Customize.get(key, value)
          type = I18n.t("column_#{key}_name")
          items << {:label => I18n.t("topic_path_item_label",
                                     :type => type,
                                     :label => value),
                    :title => I18n.t("topic_path_reduce_item_label",
                                     :type => type,
                                     :label => value),
                    :path => path(options.merge(:without => key.to_sym)),
                    :param => key}
        end
      end
    end

    items
  end

  def to_hash(options={})
    hash = {}
    ordered_keys(options).each do |key|
      value = send(key)
      hash[key.to_sym] = value unless value.blank?
    end
    hash
  end

  def attributes(options={})
    to_hash(options)
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

