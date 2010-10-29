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
      categories = []
      types = []

      conditions = conditions_from_request(request)

      Ranguba::Database.open(Ranguba::Application.config.index_db_path) do |db|
        records = db.entries.select do |record|
          conditions.collect do |condition|
            condition.call(record)
          end.flatten
        end
        records.each do |record|
          results << new(:title => record[".title"].to_s,
                         :url => record.key.to_s,
                         :category => record[".category"].to_s,
                         :type => record[".type"].to_s,
                         :body => record[".body"].to_s)
        end
      end
      { :entries => results,
        :drill_down_categories => categories,
        :drill_down_types => types }
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
          record[".category"] =~ request.query
        end
      end
      unless request.type.blank?
        conditions << Proc.new do |record|
          record[".type"] =~ request.query
        end
      end
      conditions
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
