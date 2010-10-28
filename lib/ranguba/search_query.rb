require "uri"
$KCODE = "UTF-8"

module Ranguba
  class SearchQuery
    def initialize(options=nil)
      @hash = nil
      @valid = true

      return unless options

      case options.class
      when String
        parse(options)
      when Hash
        self.hash = options
      end
    end

    def valid?
      @valid
    end

    def parse
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
      @valid = true

      new_hash.keys.each do |key|
        case key
        when "query"
        when "category"
        when "type"
        else
          @valid = false
        end
      end

      @hash = new_hash if @valid
    end
  end
end

