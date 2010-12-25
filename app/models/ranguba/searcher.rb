class Ranguba::Searcher

  attr_accessor :query, :type, :category, :page

  def initialize(options = {})
    self.query = options[:query] if options[:query]
    self.type = options[:type] if options[:type]
    self.category = options[:category] if options[:category]
  end

  def search
    ::Ranguba::Entry.select do |record|
      conditions = []
      if query
        target = record.match_target do |match_record|
          (match_record["basename"] * 1000) |
            (match_record["title"] * 100) |
            (match_record["body"])
        end
        query.split.each do |term|
          conditions << (target =~ term)
        end
      end
      conditions << (record["type"] == type) if type
      conditions << (record["category"] == category) if category
      conditions
    end
  end
end
