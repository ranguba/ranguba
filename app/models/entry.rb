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
      Ranguba::Database.open(Ranguba::Application.config.index_db_path) do |handler|
        records = handler.entries
        records.each do |record|
          results << new(:title => record[".title"],
                         :url => record.key,
                         :category => record[".category"],
                         :type => record[".type"],
                         :body => record[".body"])
        end
      end
      { :entries => results,
        :drill_down_categories => categories,
        :drill_down_types => types }
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
