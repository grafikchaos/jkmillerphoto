JKMillerPhoto::Application.routes.draw do
  # EXAMPLES
  # resources :products
  # root :to => 'welcome#index'

  # MORE INFORMATION
  # Run "rake routes" to see the routes available
  # http://guides.rubyonrails.org/routing.html

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "home#index"

  devise_for :users
end
