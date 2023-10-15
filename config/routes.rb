Rails.application.routes.draw do
  devise_for :users

  root to: 'home#index'

  get '/map', to: 'pages#map', as: :map

  get '/logout', to: 'users#logout', as: :logout

  get "/restaurant_list", to: "restaurants#restaurant_list"

  resources :restaurants
end
