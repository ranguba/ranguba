require 'test_helper'
require 'test/unit/capybara'
require 'capybara/rails'

module ActionController
  class IntegrationTest
    include Capybara
  end
end

