# -*- coding: utf-8 -*-

require 'test_helper'

class Ranguba::SearchControllerTest < ActionController::TestCase

  def setup
    setup_database
  end

  def teardown
    teardown_database
  end

  def test_routes
    base = { :controller => 'ranguba/search', :action => 'index' }
    assert_recognizes(base.merge(:search_request => 'query/q'),
                      "/search/query/q")
    assert_recognizes(base.merge(:search_request => 'query/q/type/t'),
                      "/search/query/q/type/t")
    assert_recognizes(base.merge(:search_request => 'query/q/type/t/category/c'),
                      "/search/query/q/type/t/category/c")
    assert_recognizes(base.merge(:search_request => 'type/t/category/c/query/q'),
                      "/search/type/t/category/c/query/q")
  end

  def test_index
    get :index
    assert_response :success
    assert_template "search/index"
  end

  def test_request_hash
    post :index,
         :query => "q",
         :search_request => "type/t" ,
         :page => 2
    assert_redirected_to(search_path(:search_request => "type/t/query/q"))
  end

  def test_request_hash_form
    post :index,
         :search_request => "type/t", :query => "q"
    assert_redirected_to(search_path(:search_request => "type/t/query/q"))
  end

  def test_request_string
    get :index,
        :search_request => "query/q/type/t"
    assert_response :success
    assert_template "search/index"
  end

  def test_unknown_parameter
    get :index, :search_request => "query/q/unknown/value"
    assert_response 400
    assert_template "search/bad_request"
  end

  def test_parameter_with_slash
    post :index,
         :search_request => "query/text%2Fhtml/type/html"
    assert_response(:redirect)
    assert_redirected_to(search_path(:search_request => "query/text%2Fhtml/type/html"))
  end

  def test_encoded_parameter
    encoded = URI.encode("日本語")
    post :index,
         :search_request => "query/#{encoded}/type/html"
    assert_response(:redirect)
    assert_redirected_to(search_path(:search_request => "query/#{encoded}/type/html"))
  end

  def test_first_page
    post :index,
         :search_request => "query/q",
         :page => 1
    assert_response(:redirect)
    assert_redirected_to(search_path(:search_request => "query/q"))
  end

  def test_too_large_page
    get :index,
        :search_request => "query/q",
        :page => 2
    assert_response 404
    assert_template "search/not_found"

    get :index,
        :search_request => "query/q",
        :page => 9999
    assert_response 404
    assert_template "search/not_found"
  end

  def test_too_small_page
    get :index,
        :search_request => "query/q",
        :page => 0
    assert_response 404
    assert_template "search/not_found"

    get :index,
        :search_request => "query/q",
        :page => -1
    assert_response 404
    assert_template "search/not_found"

    get :index,
        :search_request => "query/q",
        :page => -9999
    assert_response 404
    assert_template "search/not_found"
  end

end
