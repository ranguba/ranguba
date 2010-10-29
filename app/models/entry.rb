class Entry
  SUMMARY_MAX_SIZE = 30

  attr_accessor :title
  attr_accessor :url
  attr_accessor :category
  attr_accessor :type
  attr_accessor :body

  class << self

    def search(request)
      results = []
      drilldown_results = {}

      conditions = conditions_from_request(request)

      Ranguba::Database.open(Ranguba::Application.config.index_db_path) do |db|
        records = db.entries.select do |record|
          conditions.collect do |condition|
            condition.call(record)
          end.flatten
        end
        records.each do |record|
          results << new(:title => record[".title"].to_s,
                         :url => record.key.key.to_s,
                         :category => record[".category"].to_s,
                         :type => record[".type"].to_s,
                         :body => record[".body"].to_s)
        end

        drilldown_results = drilldown_groups(:records => records, :request => request)
      end
      {:entries => results,
       :drilldown_groups => drilldown_results}
    end

    private
    def conditions_from_request(request)
      conditions = []
      unless request.query.blank?
        conditions << Proc.new do |record|
          record[".title"] =~ request.query ||
          record[".body"] =~ request.query
        end
      end
      unless request.category.blank?
        conditions << Proc.new do |record|
          record[".category"] == request.category
        end
      end
      unless request.type.blank?
        conditions << Proc.new do |record|
          record[".type"] == request.type
        end
      end
      conditions
    end

    def drilldown_groups(options={})
      result = {}
      ["category", "type"].each do |column|
        next unless options[:request].send(column).nil?
        group = drilldown_group(:records => options[:records],
                                :drilldown => column,
                                :label => "_key")
        result[I18n.t("column_#{column}_name")] = group unless group.empty?
      end
      result
    end

    def drilldown_group(options={})
      result = options[:records].group(options[:drilldown])
      result = result.sort([["_nsubrecs", :descending]], :limit => 10)
      result.collect do |record|
        DrilldownItem.new(:param => options[:drilldown],
                          :value => record[options[:label]].to_s,
                          :count => record.n_sub_records)
      end
    end

  end

  def initialize(options={})
    options.each do |key, value|
      send("#{key}=", value)
    end
  end

  def summary
    !body.blank? && body.size > SUMMARY_MAX_SIZE ? "#{body[0..SUMMARY_MAX_SIZE]}..." : ""
  end

end
