class SearchController < ApplicationController
  ENTRIES_PER_PAGE = 20

  def index
    @base_path = url_for(:action => "index")
    if params[:search_request].is_a?(Hash)
      redirect_to SearchRequest.path(:base_path => @base_path,
                                     :options => params[:search_request])
      return
    end

    @search_request = SearchRequest.new
    @search_request.parse(params[:search_request])

    if @search_request.can_be_shorten?
      redirect_to SearchRequest.path(:base_path => @base_path,
                                     :options => @search_request.attributes)
      return
    end

    @search_request_params = @search_request.to_hash

    unless @search_request.valid?
      render :action => "bad_request", :status => 400
      return
    end

    options = @search_request.attributes.merge(:per_page => ENTRIES_PER_PAGE)
    search_result = Entry.search(options)
    @entries = search_result[:entries]
    @drilldown_groups = search_result[:drilldown_groups]
    @topic_path_items = @search_request.topic_path_items(:base_path => @base_path)
  end

end
