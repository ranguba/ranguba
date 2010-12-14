require 'test_helper'

class Ranguba::WelcomeControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_response :redirect
    assert_redirected_to search_path
  end
end
