module Ranguba
  class SearchQuery
    def initialize(options=nil)
      clear

      return unless options

      if options.class.ancestors.include?(String)
        parse(options)
      elsif options.class.ancestors.include?(Hash)
        self.hash = options
      end
    end

    def clear
      @valid = true
      @hash = nil
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

      hash = Hash.new
      i = 0
      while i < parts.size
        value = parts[i+1]

        case parts[i]
        when "query"
          hash[:query] = URI.decode(value)
        when "category"
          hash[:category] = URI.decode(value)
        when "type"
          hash[:type] = URI.decode(value)
        else
          @valid = false
        end

        i += 2
      end
      @hash = hash if @valid
    end

    def to_s
      return "" unless @hash
      string = []
      @hash.each do |key, value|
        string << key.to_s
        string << URI.encode(value)
      end
      string.join("/")
    end

    def hash
      @hash
    end

    def hash=(new_hash)
      clear
      return if !new_hash || new_hash.empty?

      new_hash.keys.each do |key|
        case key
        when :query
        when :category
        when :type
        else
          @valid = false
        end
      end

      @hash = new_hash if @valid
    end
  end
end

