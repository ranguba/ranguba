class SearchRequest
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :query
  attr_accessor :category
  attr_accessor :type
  attr_accessor :page

  KEYS = ["query", "category", "type", "page"]

  validate :validate_string

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

  def page=(value)
    @string = nil
    @page = value
  end

  def clear
    @string = nil
    @query = nil
    @category = nil
    @type = nil
    @page = nil
  end

  def parse(query_string="")
    clear

    query_string = (query_string || "").gsub(/^\/+|\/+$/, "")
    return if query_string.blank?

    parts = query_string.split("/")
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
        path_components << URI.encode(value)
      end
    end
    path_components.join("/")
  end

  private
  def validate_string
    return if @string.nil?
    parts = @string.split("/")
    i = 0
    while i < parts.size
      key = parts[i]
      value = parts[i+1]
      if KEYS.include?(key)
        if value.blank?
          errors.add(key.to_sym, I18n.t("search_request_blank_value",
                                        :key => key,
                                        :value => value))
        end
      else
        errors.add(key.to_sym, I18n.t("search_request_invalid_key",
                                      :key => key,
                                      :value => value))
      end
      i += 2
    end
  end
end

