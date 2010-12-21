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
        query.split.each do |term|
          conditions << ((record["basename"] =~ term) |
                         (record["title"] =~ term) |
                         (record["body"] =~ term))
        end
      end
      conditions << (record["type"] == type) if type
      conditions << (record["category"] == category) if category
      conditions
    end
  end
end
