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

  def test_search_request_hash
    post :index,
         :search_request => {:query => "q",
                             :type => "t"},
         :page => 2
    assert_redirected_to :action => "index",
                         :search_request => "query/q/type/t",
                         :page => 2
  end

  def test_search_request_string
    post :index,
         :search_request => "query/q/type/t"
    assert_response :success
    assert_template "search/index"
  end

end
