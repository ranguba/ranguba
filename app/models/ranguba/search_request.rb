class Ranguba::SearchRequest
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :query
  attr_accessor :category
  attr_accessor :type

  KEYS = [:query, :category, :type]
  DELIMITER = "/"

  validate :validate_string

  def initialize(path_info=nil, params={})
    @path_info = path_info
    @params = params
    clear
    hash = parse(@path_info)
    update(hash)
    update(@params)
  end

  def update(options={})
    options.each do |key, value|
      send("#{key.to_s}=", value) if KEYS.include?(key.to_sym)
    end
  end

  def query=(value)
    @query = value.strip.gsub(/\u{3000}/, " ")
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

  def have_key?(key)
    not send(key).blank?
  end

  def parse(string)
    hash = {}
    return hash if string.blank?
    @string = string.gsub(%r!\A/|(?:.*/?search/?)?!, '')
    @string.split(DELIMITER).each_slice(2) do |key, value|
      hash[key] = CGI.unescape(value) if KEYS.include?(key.to_sym) && !value.blank?
    end
    hash
  end

  def to_s(options={})
    path_components = []
    ordered_keys(options).each do |key|
      next if key == options[:without]
      value = send(key)
      unless value.blank?
        path_components << key.to_s
        value = value.key if value.respond_to?(:key)
        path_components << CGI.escape(value.to_s)
      end
    end
    path_components.join(DELIMITER)
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
          value = I18n.t(value, :scope => key)
          conditions << I18n.t("topic_path_item_label",
                               :type => I18n.t("column_#{key}_name"),
                               :value => value)
        end
      end
    end
    conditions.join(I18n.t("search_conditions_delimiter"))
  end

  def topic_path(options={})
    items = []
    ordered_keys(options).each do |key|
      case key
      when :query
        next if query.blank?
        terms = query.split
        terms.each do |term|
          item = Ranguba::TopicPathItem.new(key, term)
          item.value_label = term
          items << item if item.valid?
        end
      else
        item = Ranguba::TopicPathItem.new(key, send(key.to_s))
        items << item if item.valid?
      end
    end
    Ranguba::TopicPath.new(*items)
  end

  def empty?
    (query || category || type) ? false : true
  end

  def persisted?
    false
  end

  def process(params)
    RequestHandler.new(self, params).handle
  end

  private
  def validate_string
    return if @string.nil?
    @string.split(DELIMITER).each_slice(2) do |key, value|
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
      set.extend(Ranguba::CachedResultSet)
      drilldown_targets = [:category, :type].find_all do |column|
        @request.send(column).blank?
      end
      set.compute_drilldowns(drilldown_targets)
      set.compute_pagination(@params[:page], @params[:per_page])
      set
    end
  end
end

