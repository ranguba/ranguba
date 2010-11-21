class WelcomeController < ApplicationController
  def index
    redirect_to(:controller => "search", :action => "index")
  end
end
