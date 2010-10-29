class SearchController < ApplicationController

  def index
    @search_request = SearchRequest.new
    @search_request.parse(params[:search_request])
  end

end
