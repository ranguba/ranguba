class SearchController < ApplicationController

  def index
    @search_query = SearchQuery.new(params[:query])
  end

end
