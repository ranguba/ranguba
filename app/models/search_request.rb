class SearchRequest
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :query
  attr_accessor :category
  attr_accessor :type
  attr_accessor :base_params

  KEYS = [:query, :category, :type]
  DELIMITER = "/"

  validate :validate_string

  class << self
    def path(options={})
      base = options[:base_path].sub(/\/$/, "")
      search_request_options = options[:path] || new(options).to_s(options)
      [base, search_request_options].join(DELIMITER)
    end
  end

  def initialize(options={})
    clear
    parse(options[:base_params]) unless options[:base_params].blank?
    update(options)
  end

  def update(options={})
    options.each do |key, value|
      send("#{key.to_s}=", value) if KEYS.include?(key.to_sym)
    end
  end

  def query=(value)
    @query = value.strip
    @ordered_keys = @ordered_keys - [:query]
    @ordered_keys << :query
  end

  def category=(value)
    @category = value
    @ordered_keys = @ordered_keys - [:category]
    @ordered_keys << :category
  end

  def type=(value)
    @type = value
    @ordered_keys = @ordered_keys - [:type]
    @ordered_keys << :type
  end

  def clear
    @string = nil
    @query = nil
    @category = nil
    @type = nil
    @ordered_keys = []
  end

  def ordered_keys(options={})
    options[:canonical] ? KEYS : ((KEYS - @ordered_keys) + @ordered_keys)
  end

  def to_hash(options={})
    hash = {}
    ordered_keys(options).each do |key|
      next if key == options[:without]
      value = send(key.to_s)
      hash[key] = value unless value.blank?
    end
    hash
  end

  def attributes(options={})
    to_hash(options)
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
      send("#{key}=", CGI.unescape(value)) if KEYS.include?(key.to_sym) && !value.blank?
      i += 2
    end

    @string = query_string
  end

  def to_s(options={})
    path_components = []
    ordered_keys(options).each do |key|
      next if key == options[:without]
      key = key.to_s
      value = send(key)
      unless value.blank?
        path_components << key
        value = value.key if value.respond_to?(:key)
        path_components << CGI.escape(value.to_s)
      end
    end
    path_components.join("/")
  end

  def path(options={})
    options = sanitize_options(options)
    self.class.path(to_hash.merge(options))
  end

  def to_readable_string(options={})
    conditions = []
    ordered_keys(options).each do |key|
      next if key == options[:without]
      if key == :query
        conditions << query unless query.blank?
      else
        key = key.to_s
        value = send(key)
        unless value.blank?
          value = Ranguba::Customize.get(key, value)
          conditions << I18n.t("topic_path_item_label",
                               :type => I18n.t("column_#{key}_name"),
                               :value => value)
        end
      end
    end
    conditions.join(I18n.t("search_conditions_delimiter"))
  end

  def topic_path_items(options={})
    items = []
    topic_path_request = SearchRequest.new
    ordered_keys(options).each do |key|
      case key
      when :query
        next if query.blank?
        terms = query.split
        terms.each do |term|
          item = TopicPathItem.new(key, query, items)
          item.value_label = term
          items << item if item.valid?
        end
      else
        item = TopicPathItem.new(key, send(key.to_s), items)
        items << item if item.valid?
      end
    end
    items
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

  def process(params)
    RequestHandler.new(self, params).handle
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
      when KEYS.include?(key.to_sym)
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

  def sanitize_options(options={})
    KEYS.each do |key|
      options.delete(key) if options[key]
    end
    options
  end

  class RequestHandler
    def initialize(request, params)
      @request = request
      @params = params
    end

    def handle
      searcher = Ranguba::Searcher.new(:query => @request.query,
                                       :type => @request.type,
                                       :category => @request.category)
      set = searcher.search
      set.extend(CachedResultSet)
      drilldown_targets = [:category, :type].find_all do |column|
        @request.send(column).blank?
      end
      set.compute_drilldowns(drilldown_targets)
      set.compute_pagination(@params[:page], @params[:per_page])
      set
    end

  end
end

