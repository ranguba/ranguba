class SearchController < ApplicationController
  SUMMARY_SIZE = 140

  def index

    @search_request = SearchRequest.new(request.path_info, params)
    if request.post?
      new_params = { :search_request => params[:search_request] }
      redirect_to new_params.merge(:search_request => @search_request.to_s).tap{|a| p a }
      return
    end

    if @search_request.valid?
      search_options = @search_request.attributes.merge(:page => params[:page])
    else
      handle_bad_request
      search_options = {}
    end

    setup_search_result

    if @bad_request
      render :action => "bad_request", :status => 400
    else
      setup_search_result_title
      @summary_size = SUMMARY_SIZE
    end
  rescue Groonga::TooSmallPage
    handle_bad_request
    setup_search_result
    render :action => "not_found", :status => 404
  rescue Groonga::TooLargePage
    handle_bad_request
    setup_search_result
    render :action => "not_found", :status => 404
  end

  private

  def handle_bad_request
    @bad_request = @search_request
    @search_request = SearchRequest.new
  end

  def setup_search_result
    @result_set = @search_request.process(params)
    @topic_path_items = @search_request.topic_path_items
  end

  def setup_search_result_title
    return if @search_request.empty?
    paginated_records = @result_set.paginated_records
    if paginated_records.total_pages > 1
      title = I18n.t("search_result_title_paginated",
                     :conditions => @search_request.to_readable_string,
                     :page => paginated_records.current_page,
                     :max_page => paginated_records.total_pages)
    else
      title = I18n.t("search_result_title",
                     :conditions => @search_request.to_readable_string)
    end
    @title = [title, @ranguba_template.title].join(I18n.t("title_delimiter"))
  end
end
