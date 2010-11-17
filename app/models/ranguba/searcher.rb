class Ranguba::Searcher

  attr_accessor :query, :type, :category, :page

  def search
    conditions = []
    ::Ranguba::Entry.select{|record|
      if query
        query.split.each do |term|
          conditions << ((record.key.key =~ term) |
                         (record["title"] =~ term) |
                         (record["body"] =~ term))
        end
      end
      conditions << (record["type"] =~ type) if type
      conditions
    }
  end
end
