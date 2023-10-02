Rails.application.routes.draw do
  devise_for :users

  root to: 'home#index'

  get '/logout', to: 'users#logout', as: :logout

  resources :restaurants
end
