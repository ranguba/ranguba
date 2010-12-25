class Ranguba::SearchController < ApplicationController
  SUMMARY_SIZE = 140

  if Rails.env.production?
    rescue_from StandardError do |exception|
      handle_bad_request
      begin
        render :action => "internal_server_error", :status => 500
      rescue
        @topic_path = Ranguba::TopicPath.new
        render :action => "internal_server_error", :status => 500
      end
    end
  end

  rescue_from Groonga::TooSmallPage, Groonga::TooLargePage do |ex|
    handle_bad_request
    render :action => "not_found", :status => 404
  end

  def index
    start_time = Time.now.to_f
    @search_request = Ranguba::SearchRequest.new(request.path_info, params)
    if request.post?
      new_params = { :search_request => params[:search_request] }
      redirect_to new_params.merge(:search_request => @search_request.to_s)
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
    end_time = Time.now.to_f
    @elapsed_time = end_time - start_time
  end

  private

  def handle_bad_request
    @bad_request = @search_request
    @search_request = Ranguba::SearchRequest.new(request.path_info, params)
    @topic_path = @search_request.topic_path
  end

  def setup_search_result
    @result_set = @search_request.process(params)
    @topic_path = @search_request.topic_path
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
