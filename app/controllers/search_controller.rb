class SearchController < ApplicationController

  def index
    @search_query = SearchQuery.new
    @search_query.parse(params[:query])
  end

end
