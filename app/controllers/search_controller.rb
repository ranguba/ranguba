class SearchController < ApplicationController
  SUMMARY_SIZE = 140

  def index
    if /\/\z/ !~ request.env["REQUEST_URI"]
      redirect_to("#{request.env['REQUEST_URI']}/")
      return
    end

    @base_path = url_for(:action => "index")
    if params[:search_request].is_a?(Hash)
      redirect_to params.merge(:search_request => SearchRequest.new(params[:search_request]).to_s)
      return
    end

    @search_request = SearchRequest.new
    @search_request.parse(raw_search_request)
    @search_request_params = @search_request.to_hash

    if @search_request.valid?
      search_options = @search_request.attributes.merge(:page => params[:page])
      @search_request.base_params = @search_request.to_s
      @canonical = @search_request.path(:base_path => @base_path,
                                        :canonical => true)
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
  # I have to use this instead of params[:search_request], because "%2F"
  # in urls are always unescaped by Rails itself. So, if the path is
  # "query/text%2Fhtml", params[:search_request] will be "query/text/html".
  # To avoid this problem, I get the raw version of the part of the path
  # from the PATH_INFO.
  def raw_search_request
    path = request.env["PATH_INFO"]
    base = url_for(:controller => params[:controller],
                   :action => params[:action],
                   :only_path => true)
    path.sub(base, "").sub(/\?.*$/, "")
  end

  def handle_bad_request
    @bad_request = @search_request
    @search_request = SearchRequest.new
  end

  def setup_search_result
    @result_set = @search_request.process(params)
    @topic_path_items = @search_request.topic_path_items(:base_path => @base_path)
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
    @title = [title, Ranguba::Customize.title].join(I18n.t("title_delimiter"))
  end
end
