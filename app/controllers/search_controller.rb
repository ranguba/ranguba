class SearchController < ApplicationController

  def index
    @base_path = url_for(:action => "index")
    if params[:search_request].is_a?(Hash)
      redirect_to SearchRequest.path(:base_path => @base_path,
                                     :options => params[:search_request])
      return
    end

    @search_request = SearchRequest.new
    @search_request.parse(params[:search_request])
    @search_request_params = @search_request.to_hash

    unless @search_request.valid?
      render :action => "bad_request", :status => 400
      return
    end

    search_result = Entry.search(@search_request)
    @entries = search_result[:entries]
    @drilldown_groups = search_result[:drilldown_groups]
  end

end
