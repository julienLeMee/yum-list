Rails.application.routes.draw do
  devise_for :users

  root to: 'home#index'

  get '/map', to: 'pages#map', as: :map

  get '/categories', to: 'restaurants#categories', as: :restaurant_categories
  get '/tested-restaurants', to: 'restaurants#tested_restaurants', as: :tested_restaurants
  get '/untested-restaurants', to: 'restaurants#untested_restaurants', as: :untested_restaurants

  get '/dashboard', to: 'users#show', as: :dashboard
  get '/logout', to: 'users#logout', as: :logout

  get '/restaurant_list', to: 'restaurants#restaurant_list'
  get '/restaurant_addresses', to: 'restaurants#restaurant_addresses'

  resources :restaurants

  resources :friendships, only: [:new, :create, :update, :destroy]
  get '/friends', to: 'users#friends', as: :friends
  post '/friendships', to: 'friendships#create', as: :create_friendship

  get '/users/:id/restaurants', to: 'users#friend_restaurants', as: :user_restaurants
end
