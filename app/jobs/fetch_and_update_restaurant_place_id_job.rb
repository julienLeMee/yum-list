require 'httparty'

class FetchAndUpdateRestaurantPlaceIdJob < ApplicationJob
  queue_as :default

  def perform(restaurant_id)
    restaurant = Restaurant.find_by(id: restaurant_id)
    return unless restaurant

    # Ignorer si déjà un place_id valide
    if restaurant.place_id.present? && 
       restaurant.place_id != "id place-id-input" && 
       !restaurant.place_id.start_with?("id ")
      Rails.logger.info "Restaurant #{restaurant.id} already has valid place_id"
      # Même avec un place_id valide, on peut essayer de récupérer l'image si manquante
      FetchRestaurantImageJob.perform_later(restaurant.id) if restaurant.image_url.blank?
      return
    end

    # Chercher le place_id depuis le nom et l'adresse
    place_id = GooglePlacesSearchService.find_place_id(restaurant.name, restaurant.address)
    
    if place_id.present?
      restaurant.update(place_id: place_id)
      
      # Récupérer les détails complets et l'image
      place_details = get_place_details(place_id)
      
      if place_details && place_details['status'] == 'OK'
        result = place_details['result']
        
        # Mettre à jour les coordonnées
        if result['geometry']
          restaurant.update(
            latitude: result['geometry']['location']['lat'],
            longitude: result['geometry']['location']['lng']
          )
        end

        # Récupérer l'image immédiatement (synchrone si appelé depuis create, async sinon)
        if result['photos'].present?
          photos = result['photos']
          selected_index = photos.length > 1 ? 1 : 0
          selected_index = [selected_index, 2].min if photos.length > 2
          selected_photo = photos[selected_index]
          
          image_url = GooglePlacesSearchService.get_place_photo_url(selected_photo['photo_reference'], 1200)
          restaurant.update(image_url: image_url) if image_url.present?
        end

        Rails.logger.info "Successfully updated restaurant #{restaurant.id} with place_id: #{place_id}"
      end
    else
      Rails.logger.warn "Could not find place_id for restaurant #{restaurant.id}: #{restaurant.name}"
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching place_id for restaurant #{restaurant_id}: #{e.message}"
  end

  private

  def get_place_details(place_id)
    api_key = ENV['GOOGLE_PLACES_API_KEY']
    return nil unless api_key.present?

    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
      place_id: place_id,
      fields: 'geometry,photos',
      key: api_key
    }

    response = HTTParty.get(url, query: params)
    return nil unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error "Error getting place details: #{e.message}"
    nil
  end
end

