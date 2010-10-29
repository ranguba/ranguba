class SearchController < ApplicationController

  def index
    if params[:search_request].is_a?(Hash)
      path = SearchRequest.new(params[:search_request]).to_s
      base = request.env["PATH_INFO"]
      redirect_to "#{base}/#{path}"
      return
    end

    @search_request = SearchRequest.new
    @search_request.parse(params[:search_request])

    unless @search_request.valid?
      render :action => "bad_request", :status => 400
    end
  end

end
