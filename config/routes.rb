Rails.application.routes.draw do
    devise_for :users

    resource :user, only: [:show, :edit, :update]

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

    resources :friendships, only: [:new, :create, :update, :destroy] do
        collection do
          get :pending_requests
        end
        member do
          patch :accept
          delete :reject
        end
      end

    get '/friends', to: 'users#friends', as: :friends
    get '/users/:id/restaurants', to: 'users#friend_restaurants', as: :user_restaurants
    post 'friendships/:id/resend_request', to: 'friendships#resend_request', as: 'friendship_resend_request'
    
    get '/notifications', to: 'users#notifications', as: :notifications
    patch '/notifications/:id/read', to: 'users#mark_notification_as_read', as: :mark_notification_read
  end
