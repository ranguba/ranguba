require "csv"

module Ranguba
  class CrawlTargetLoader
    def initialize(path)
      @path = path
    end

    def load
      File.open(@path, "r:utf-8") do |input|
        case @path
        when /\.csv\z/i
          targets = []
          CSV.new(input, headers: true, skip_blanks: true).each do |row|
            targets << CrawlTarget.new(row["url"], type: row["type"])
          end
          targets
        when /\.ya?ml\z/i
          YAML.load(input).collect do |target|
            CrawlTarget.new(target["url"],
                            type: target["type"],
                            category: target["category"])
          end
        else
          message = "crawl targets file must be CSV or YAML: <#{@path}>"
          raise ArgumentError, message
        end
      end
    end
  end
end
