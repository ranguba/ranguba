Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root "ranguba/welcome#index"

  get "search/(*search_request)" => "ranguba/search#index", :as => :search
  get "help" => "ranguba/help#index", :as => :help
end
