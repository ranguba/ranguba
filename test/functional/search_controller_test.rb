# coding: utf-8
require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  def setup
    setup_database
  end

  def teardown
    teardown_database
  end

  def test_index
    get :index
    assert_response :success
    assert_template "search/index"
  end

  def test_request_hash
    post :index,
         :search_request => {:query => "q",
                             :type => "t"},
         :page => 2
    assert_redirected_to :action => "index",
                         :search_request => "query/q/type/t",
                         :page => 2
  end

  def test_request_hash_drilldown
    post :index,
         :search_request => {:type => "t",
                             :query => "q"}
    assert_redirected_to :action => "index",
                         :search_request => "type/t/query/q"
  end

  def test_request_string
    post :index,
         :search_request => "query/q/type/t"
    assert_response :success
    assert_template "search/index"
  end

  def test_unknown_parameter
    post :index,
         :search_request => "query/q/unknown/value"
    assert_response 400
    assert_template "search/bad_request"
  end

  def test_parameter_with_slash
    post :index,
         :search_request => "query/text%2Fhtml/type/html"
    assert_response :success
    assert_template "search/index"
  end

  def test_encoded_parameter
    encoded = URI.encode("日本語")
    post :index,
         :search_request => "query/#{encoded}/type/html"
    assert_response :success
    assert_template "search/index"
  end

  def test_first_page
    post :index,
         :search_request => "query/q",
         :page => 1
    assert_response :success
    assert_template "search/index"
  end

  def test_too_large_page
    post :index,
         :search_request => "query/q",
         :page => 2
    assert_response 404
    assert_template "search/not_found"

    post :index,
         :search_request => "query/q",
         :page => 9999
    assert_response 404
    assert_template "search/not_found"
  end

  def test_too_small_page
    post :index,
         :search_request => "query/q",
         :page => 0
    assert_response 404
    assert_template "search/not_found"

    post :index,
         :search_request => "query/q",
         :page => -1
    assert_response 404
    assert_template "search/not_found"

    post :index,
         :search_request => "query/q",
         :page => -9999
    assert_response 404
    assert_template "search/not_found"
  end

end
