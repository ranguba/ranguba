require "test_helper"

class Ranguba::WelcomeControllerTest < ActionDispatch::IntegrationTest
  def test_index
    get root_url
    assert_response :redirect
    assert_redirected_to search_path
  end
end
