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
      return
    end

    search_result = Entry.search(@search_request)
    @entries = search_result[:entries]
  end

end
