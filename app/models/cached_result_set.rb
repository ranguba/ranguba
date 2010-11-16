module CachedResultSet
  RECORDS_PER_PAGE = 10

  def drilldown(key)
    records = group(key).sort([["_nsubrecs", :descending]])
    records.collect do |record|
      DrilldownItem.new(:param => key,
                        :value => record.key,
                        :count => record.n_sub_records)
    end
  end

  attr_reader :drilldowns
  def compute_drilldowns(columns)
    @drilldowns = {}
    columns.each do |column|
      items = drilldown(column.to_s)
      @drilldowns[column.to_s] = items unless items.empty?
    end
  end

  attr_reader :paginated_records
  def compute_pagination(page, per_page)
    page = nil if page.blank?
    page = (page || 1).to_i
    per_page = per_page || RECORDS_PER_PAGE
    paginated_records = @records.paginate([["_score", :descending],
                                           ["title", :ascending]],
                                          :page => page,
                                          :size => per_page)
    singleton_class = (class << paginated_records; self; end)
    instantiate_record = lambda do |record|
      instantiate(record)
    end
    singleton_class.send(:define_method, :each) do |&block|
      super() do |record|
        block.call(instantiate_record.call(record.key))
      end
    end
    @paginated_records = paginated_records
  end
end
