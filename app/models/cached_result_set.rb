module CachedResultSet
  RECORDS_PER_PAGE = 10

  def drilldown(key)
    records = group(key).sort([["_nsubrecs", :descending]])
    records.collect do |record|
      DrilldownEntry.new(:key => key,
                         :value => record.key.key,
                         :count => record.n_sub_records)
    end
  end

  attr_reader :drilldowns
  def compute_drilldowns(columns)
    @drilldowns = {}
    columns.each do |column|
      entries = drilldown(column.to_s)
      @drilldowns[column.to_s] = entries unless entries.empty?
    end
  end

  attr_reader :paginated_records
  def compute_pagination(page, per_page)
    page = nil if page.blank?
    page = (page || 1).to_i
    per_page = per_page || RECORDS_PER_PAGE
    @paginated_records = paginate([["_score", :descending],
                                   ["title", :ascending]],
                                  :page => page,
                                  :size => per_page)
  end
end
