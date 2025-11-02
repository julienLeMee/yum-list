require 'net/http'
require 'json'
require 'httparty'

class RestaurantsController < ApplicationController
#   def index
#     if params[:query].present?
#       @restaurants = current_user.restaurants.where('name LIKE ? OR category LIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
#     else
#       @restaurants = current_user.restaurants
#     end
#   end

def index
    if params[:user_id] && current_user.id != params[:user_id].to_i
      # Affichage des restaurants d'un ami
      @user = User.find(params[:user_id])
      @restaurants_relation = @user.restaurants
      @restaurants = @restaurants_relation
      @editable = false
      @debug_message = "Affichage des restaurants d'un ami"
      logger.debug "Affichage des restaurants d'un ami"
    else
      # Affichage des restaurants de l'utilisateur actuel
      @user = current_user
      if params[:query].present?
        @restaurants_relation = @user.restaurants.where('name LIKE ? OR category LIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
      else
        @restaurants_relation = @user.restaurants
      end
      @restaurants = @restaurants_relation
      @editable = true
      @debug_message = "Affichage des restaurants de l'utilisateur actuel"
      logger.debug "Affichage des restaurants de l'utilisateur actuel"
    end
    
    # Récupérer le dernier restaurant ajouté (indépendamment des filtres)
    @last_added_restaurant = @user.restaurants.order(created_at: :desc).first
    
    # Récupérer automatiquement les images manquantes en arrière-plan (max 5 à la fois)
    # Utiliser une requête SQL pour éviter de charger tous les restaurants
    restaurants_without_images = @restaurants_relation
      .where(image_url: [nil, ''])
      .where.not(place_id: [nil, '', 'id place-id-input'])
      .where.not("place_id LIKE ?", 'id %')
      .limit(5)
    
    restaurants_without_images.each do |restaurant|
      FetchRestaurantImageJob.perform_later(restaurant.id)
    end
  end

  def categories
    @categories = current_user.restaurants.select(:category).distinct.pluck(:category)
  end

  def tested_restaurants
    @restaurants = current_user.restaurants.where(tested: true)
    # Récupérer le dernier restaurant ajouté (indépendamment des filtres)
    @last_added_restaurant = current_user.restaurants.order(created_at: :desc).first
    # Récupérer automatiquement les images manquantes en arrière-plan
    fetch_missing_images_for_restaurants(@restaurants)
  end

  def untested_restaurants
    @restaurants = current_user.restaurants.where(tested: false)
    # Récupérer le dernier restaurant ajouté (indépendamment des filtres)
    @last_added_restaurant = current_user.restaurants.order(created_at: :desc).first
    # Récupérer automatiquement les images manquantes en arrière-plan
    fetch_missing_images_for_restaurants(@restaurants)
  end

  def restaurant_list
    @restaurants = current_user.restaurants

    render json: { restaurants: @restaurants.as_json(only: [:id, :name, :latitude, :longitude, :category]) }
  end

  def show
    @restaurant = Restaurant.find_by(id: params[:id])
    if @restaurant
        @related_restaurants = Restaurant.where(user_id: current_user.id, category: @restaurant.category).where.not(id: @restaurant.id).limit(5)
      @user = @restaurant.user
      @editable = current_user == @user
      @reviews = @restaurant.reviews

      # Essayez d'obtenir les horaires à partir du modèle
      if @restaurant.opening_hours.present?
        @opening_hours = JSON.parse(@restaurant.opening_hours)
      elsif params[:opening_hours].present?
        # Vérifiez si params[:opening_hours] est déjà un tableau
        if params[:opening_hours].is_a?(Array)
          @opening_hours = params[:opening_hours] # Assignez directement si c'est déjà un tableau
        else
          @opening_hours = JSON.parse(params[:opening_hours]) # Sinon, parsez
        end
      else
        # Si aucune donnée n'est présente, initialisez comme tableau vide
        @opening_hours = []
      end

      # Récupérer l'image automatiquement si manquante
      if @restaurant.image_url.blank? && @restaurant.place_id.present? && 
         @restaurant.place_id != "id place-id-input" && !@restaurant.place_id.start_with?("id ")
        FetchRestaurantImageJob.perform_later(@restaurant.id)
      end

    else
      redirect_to restaurants_path, alert: "Restaurant non trouvé."
    end
  end

  def new
    @restaurant = Restaurant.new
  end

  def create
    @restaurant = current_user.restaurants.new(restaurant_params)
    @restaurant.place_id = params[:place_id] if params[:place_id].present?

    if @restaurant.save
      # Vérifier que le place_id est valide (pas un placeholder)
      if @restaurant.place_id.present? && @restaurant.place_id != "id place-id-input" && !@restaurant.place_id.start_with?("id ")
        place_details = get_place_details(@restaurant.place_id)
        Rails.logger.debug "Place Details: #{place_details.inspect}"

        if place_details && place_details['status'] == 'OK' && place_details['result']
          opening_hours = place_details['result']['opening_hours']

          if opening_hours
            hours_text = opening_hours['weekday_text']
            @restaurant.opening_hours = hours_text.to_json
          else
            @restaurant.opening_hours = nil
          end

          if place_details['result']['geometry']
            @restaurant.latitude = place_details['result']['geometry']['location']['lat']
            @restaurant.longitude = place_details['result']['geometry']['location']['lng']
          end

          # Récupérer l'image IMMÉDIATEMENT (synchrone) pour affichage immédiat
          if place_details['result']['photos'].present?
            photos = place_details['result']['photos']
            # Prendre la 2ème ou 3ème photo pour éviter les images de carte
            selected_index = photos.length > 1 ? 1 : 0
            selected_index = [selected_index, 2].min if photos.length > 2
            selected_photo = photos[selected_index]
            
            @restaurant.image_url = get_place_photo_url(selected_photo['photo_reference'], 1200)
          end
          @restaurant.save
        end
      else
        # Si pas de place_id valide, essayer de le trouver depuis le nom/adresse (synchrone pour avoir l'image immédiatement)
        place_id = GooglePlacesSearchService.find_place_id(@restaurant.name, @restaurant.address)
        
        if place_id.present?
          @restaurant.update(place_id: place_id)
          place_details = get_place_details(place_id)
          
          if place_details && place_details['status'] == 'OK'
            result = place_details['result']
            
            # Mettre à jour les coordonnées
            if result['geometry']
              @restaurant.latitude = result['geometry']['location']['lat']
              @restaurant.longitude = result['geometry']['location']['lng']
            end
            
            # Récupérer l'image immédiatement
            if result['photos'].present?
              photos = result['photos']
              selected_index = photos.length > 1 ? 1 : 0
              selected_index = [selected_index, 2].min if photos.length > 2
              selected_photo = photos[selected_index]
              
              @restaurant.image_url = get_place_photo_url(selected_photo['photo_reference'], 1200)
            end
            
            @restaurant.save
          end
        end
      end

      # Envoyer des notifications à tous les amis acceptés
      accepted_friends = current_user.accepted_friends.to_a
      if accepted_friends.any?
        NewRestaurantNotificationNotifier.with(restaurant: @restaurant, sender: current_user)
                                         .deliver(accepted_friends)
      end

      respond_to do |format|
        format.html { redirect_to restaurant_path(@restaurant) }
        # format.turbo_stream { render turbo_stream: turbo_stream.replace("form", partial: "restaurants/restaurant", locals: { restaurant: @restaurant }) }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("form", partial: "restaurants/form", locals: { restaurant: @restaurant }), status: :unprocessable_entity }
      end
    end
  end

  def edit
    @restaurant = Restaurant.find(params[:id])
  end

  def update
    logger.debug "Received params: #{params.inspect}"
    @restaurant = Restaurant.find(params[:id])

    if @restaurant.update(restaurant_params)
      # Vérifier que le place_id est valide (pas un placeholder)
      if @restaurant.place_id.present? && @restaurant.place_id != "id place-id-input" && !@restaurant.place_id.start_with?("id ")
        place_details = get_place_details(@restaurant.place_id)
        Rails.logger.debug "See place Details: #{place_details.inspect}"

        # Vérifier si place_details n'est pas nil
        if place_details && place_details["status"] == "OK"
          @opening_hours = place_details.dig("result", "opening_hours", "weekday_text")

          # Mettez à jour tous les attributs en une seule fois
          # Récupérer l'image si disponible
          image_url = nil
          if place_details['result']['photos'].present? && place_details['result']['photos'].first.present?
            photo_reference = place_details['result']['photos'].first['photo_reference']
            image_url = get_place_photo_url(photo_reference, 800)
          end

          @restaurant.update(
            opening_hours: @opening_hours.to_json,
            latitude: place_details['result']['geometry']['location']['lat'],
            longitude: place_details['result']['geometry']['location']['lng'],
            image_url: image_url
          )

          # Lancer la job pour récupérer une image de meilleure qualité
          FetchRestaurantImageJob.perform_later(@restaurant.id) if @restaurant.place_id.present? && image_url.present?
        else
          # Si place_details est nil ou que le statut n'est pas OK
          Rails.logger.warn "Place details not found or status not OK"
          @opening_hours = []
        end
      end

      redirect_to restaurant_path(@restaurant)
    else
      render :edit
    end
  end

  def destroy
    @restaurant = Restaurant.find(params[:id])
    @restaurant.destroy
    redirect_to restaurants_path(@restaurant), status: :see_other, notice: "Restaurant supprimé avec succès."
  end

  def restaurant_addresses
    @addresses = current_user.restaurants.pluck(:address)
    render json: { addresses: @addresses }
  end

  private

  def restaurant_params
    params.require(:restaurant).permit(:name, :place_id, :latitude, :longitude, :address, :description, :category, :rating, :tested)
  end

  def get_place_details(place_id)
    api_key = ENV['GOOGLE_PLACES_API_KEY']
    return nil unless api_key.present?
    
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
      place_id: place_id,
      fields: 'name,geometry,opening_hours,photos',
      key: api_key
    }

    response = HTTParty.get(url, query: params)

    if response.success?
      Rails.logger.debug "API response: #{response.body[0..200]}"
      JSON.parse(response.body)
    else
      Rails.logger.warn "Failed to get place details for place_id: #{place_id}"
      nil
    end
  end

  def get_place_photo_url(photo_reference, max_width = 800)
    api_key = ENV['GOOGLE_PLACES_API_KEY']
    "https://maps.googleapis.com/maps/api/place/photo?maxwidth=#{max_width}&photo_reference=#{photo_reference}&key=#{api_key}"
  end

  def fetch_missing_images_for_restaurants(restaurants)
    # Récupérer automatiquement les images manquantes en arrière-plan (max 5 à la fois)
    restaurants_without_images = restaurants
      .where(image_url: [nil, ''])
      .where.not(place_id: [nil, '', 'id place-id-input'])
      .where.not("place_id LIKE ?", 'id %')
      .limit(5)
    
    restaurants_without_images.each do |restaurant|
      FetchRestaurantImageJob.perform_later(restaurant.id)
    end
  end
end
