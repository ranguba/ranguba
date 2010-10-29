class SearchController < ApplicationController

  def index
    unless params[:search_request].is_a?(String)
      path = SearchRequest.new(params[:search_request]).to_s
      base = request.env["PATH_INFO"]
      redirect_to "#{base}/#{path}"
      return
    end

    @search_request = SearchRequest.new
    @search_request.parse(params[:search_request])
  end

end
