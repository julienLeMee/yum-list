Rails.application.routes.draw do
  devise_for :users

  root to: 'home#index'

  get '/map', to: 'pages#map', as: :map

  get '/tested-restaurants', to: 'restaurants#tested_restaurants', as: :tested_restaurants
  get '/untested-restaurants', to: 'restaurants#untested_restaurants', as: :untested_restaurants

  get '/logout', to: 'users#logout', as: :logout

  get "/restaurant_list", to: "restaurants#restaurant_list"

  resources :restaurants
end
