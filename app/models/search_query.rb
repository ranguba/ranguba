class SearchQuery
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :query
  attr_accessor :category
  attr_accessor :type

  def initialize(options=nil)
    clear

    return unless options

    if options.class.ancestors.include?(String)
      parse(options)
    elsif options.class.ancestors.include?(Hash)
      self.apply(options)
    end
  end

  def clear
    @valid = true
    self.query = nil
    self.category = nil
    self.type = nil
  end

  def valid?
    @valid
  end

  def parse(query_string="")
    clear

    return if query_string.empty?
        
    parts = query_string.gsub(/^\/+|\/+$/, "").split("/")
    if parts.size % 2 > 0
      @valid = false
      return
    end

    i = 0
    while i < parts.size
      value = parts[i+1]

      case parts[i]
      when "query"
        self.query = URI.decode(value)
      when "category"
        self.category = URI.decode(value)
      when "type"
        self.type = URI.decode(value)
      else
        @valid = false
      end

      i += 2
    end
  end

  def to_s
    return "" unless valid?

    path_components = []
    {:query => query,
     :category => category,
     :type => type}.each do |key, value|
      unless value.blank?
        path_components << key.to_s
        path_components << URI.encode(value)
      end
    end
    path_components.join("/")
  end

  def apply(new_hash)
    clear
    return if !new_hash || new_hash.empty?

    new_hash.each do |key, value|
      case key
      when :query
        self.query = value
      when :category
        self.category = value
      when :type
        self.type = value
      else
        @valid = false
      end
    end
  end
end

