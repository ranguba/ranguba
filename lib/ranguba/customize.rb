module Ranguba
  class Customize
    class << self
      def load
        @@title = File.read("#{base}/title.txt").strip
        @@content_header = File.read("#{base}/content_header.txt")
        @@content_footer = File.read("#{base}/content_footer.txt")

        @@categories = read_key_value_list("#{base}/categories.txt")
        @@types = read_key_value_list("#{base}/types.txt")
      end

      def content_header
        @@content_header
      end

      def content_footer
        @@content_footer
      end

      def category(key)
         @@categorie[key] || key
      end

      def type(key)
         @@types[key] || key
      end

      def get(table, key)
        send(table, key)
      end

      private
      def base
       "#{::Rails.root.to_s}/config/customize"
      end

      def read_key_value_list(path)
        contents = File.read(path)
        hash = {}
        contents.split("\n").each do |line|
          line.strip!
          next if line.blank?
          parts = line.split
          hash[parts[0]] = parts[1]
        end
        hash
      end
    end
  end
end

