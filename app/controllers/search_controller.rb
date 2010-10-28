require "ranguba/search_query"

class SearchController < ApplicationController

  def index
    search_query = Ranguba::SearchQuery.new(params[:query])
  end

end
