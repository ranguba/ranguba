module Ranguba
  class Customize
    class << self
      @@titles = {}
      @@content_headers = {}
      @@content_footers = {}
      @@categories = {}
      @@types = {}

      def title
        unless @@titles[I18n.locale]
          title = read("#{base}/title.#{I18n.locale.to_s}.txt").strip
          title = I18n.t("global_title") if title.blank?
          @@titles[I18n.locale] = title
        end
        @@titles[I18n.locale]
      end

      def content_header
        @@content_headers[I18n.locale] ||= read("#{base}/content_header.#{I18n.locale.to_s}.txt")
      end

      def content_footer
        @@content_footers[I18n.locale] ||= read("#{base}/content_footer.#{I18n.locale.to_s}.txt")
      end

      def category(key)
        @@categories[I18n.locale] ||= read_hash("#{base}/categories.#{I18n.locale.to_s}.txt")
        @@categories[I18n.locale][key] || key
      end

      def type(key)
        @@types[I18n.locale] ||= read_hash("#{base}/types.#{I18n.locale.to_s}.txt")
        @@types[I18n.locale][key] || key
      end

      def get(table, key)
        send(table.to_s, key)
      end

      private
      def base
       Ranguba::Application.config.customize_base_path
      end

      def read(path)
        File.exists?(path) ? File.read(path) : ""
      end

      def read_hash(path)
        contents = read(path)
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

