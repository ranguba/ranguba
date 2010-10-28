class SearchResult < ActiveModel::Base

  attr_accessor :query
  attr_accessor :category
  attr_accessor :type

  class << self

    def find(options={})
      options[:query] ||= ""
      options[:category] ||= ""
      options[:type] ||= ""

      results = []
      categories = []
      types = []

      records = entries_index.select do |record|
        record["body"] =~ options[:query]
      end
      records.each do |record|
        record = record.key
        results << self.new(:title => record[".title"],
                            :url => record.key,
                            :type => record[".type"],
                            :category => record[".category"],
                            :body => record[".body"])
      end
      { :entries => results,
        :drill_down_categories => categories,
        :drill_down_types => types }
    end

    @private
    def entries_index
      Ranguba::Index.new.open(...).entries
    end

  end

end
