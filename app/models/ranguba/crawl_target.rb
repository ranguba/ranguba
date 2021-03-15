module Ranguba
  class CrawlTarget
    attr_reader :url
    attr_reader :type
    attr_reader :category

    def initialize(url, type: nil, category: nil)
      @url = url
      @type = (type || :web).to_sym
      @category = ensure_category(category)
    end

    def match?(url)
      url.start_with?(@url)
    end

    private
    def ensure_category(category)
      return nil if category.nil?
      if category.is_a?(Hash)
        Category.new(category["id"], category["labels"] || {})
      else
        Category.new(category, {})
      end
    end

    class Category
      attr_reader :id
      attr_reader :labels

      def initialize(id, labels)
        @id = id
        @labels = labels
      end

      def label(locale=I18n.locale)
        @labels[locale] || id
      end
    end
  end
end
