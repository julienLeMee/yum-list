Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

# GET /restaurants : Affiche la liste de tous les restaurants.
# GET /restaurants/new : Affiche le formulaire de création d'un nouveau restaurant.
# POST /restaurants : Crée un nouveau restaurant.
# GET /restaurants/:id : Affiche les détails d'un restaurant spécifique.
# GET /restaurants/:id/edit : Affiche le formulaire de modification d'un restaurant.
# PATCH /restaurants/:id : Met à jour un restaurant spécifique.
# DELETE /restaurants/:id : Supprime un restaurant spécifique.

  resources :restaurants
end
