module Ranguba
  class Customize
    class << self
      @@titles = {}
      @@content_headers = {}
      @@content_footers = {}
      @@categories = {}
      @@types = {}

      @@category_definitions = nil
      @@type_definitions = nil

      def title
        unless @@titles[I18n.locale]
          title = read_template("#{base}/templates/title.#{I18n.locale.to_s}.txt").strip
          title = I18n.t("global_title") if title.blank?
          @@titles[I18n.locale] = title
        end
        @@titles[I18n.locale]
      end

      def content_header
        @@content_headers[I18n.locale] ||= read_template("#{base}/templates/header.#{I18n.locale.to_s}.txt")
      end

      def content_footer
        @@content_footers[I18n.locale] ||= read_template("#{base}/templates/footer.#{I18n.locale.to_s}.txt")
      end

      def category(key)
        @@categories[I18n.locale] ||= read_hash("#{base}/messages/categories.#{I18n.locale.to_s}.txt")
        @@categories[I18n.locale][key] || key
      end

      def type(key)
        @@types[I18n.locale] ||= read_hash("#{base}/messages/types.#{I18n.locale.to_s}.txt")
        @@types[I18n.locale][key] || key
      end

      def get(table, key)
        send(table.to_s, key)
      end

      def category_for_url(url="")
        prefix, category = category_definitions.select do |prefix, category|
          url.start_with?(prefix)
        end.max_by do |prefix, category|
          prefix.length
        end
        category.blank? ? "unknown" : category
      end

      def normalize_type(source="")
        type = type_for_mime(source) || source.gsub(/^[^\/]+\/|\s*;\s*.*\z/, "").strip
        type.blank? ? "unknown" : type
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

      def read_template(path)
        contents = read(path)
        if contents.blank?
          path = path.gsub(/\.#{I18n.locale.to_s}/, "")
          contents = read(path)
        end
        contents
      end

      def category_definitions
        @@category_definitions ||= read_hash("#{base}/master/categories.txt")
      end

      def type_definitions
        @@type_definitions ||= read_hash("#{base}/master/types.txt")
      end

      def type_for_mime(source)
        source = source.sub(/\s*;\s*.*\z/, "").strip
        mime, type = type_definitions.select do |mime, type|
          source == mime
        end.max_by do |mime, type|
          mime.length
        end
        type
      end
    end
  end
end

