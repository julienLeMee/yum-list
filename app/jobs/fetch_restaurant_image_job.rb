require 'httparty'

class FetchRestaurantImageJob < ApplicationJob
  queue_as :default

  def perform(restaurant_id)
    restaurant = Restaurant.find_by(id: restaurant_id)
    return unless restaurant

    # Si pas de place_id valide, essayer de le trouver d'abord
    if restaurant.place_id.blank? || 
       restaurant.place_id == "id place-id-input" || 
       restaurant.place_id.start_with?("id ")
      
      # Lancer la job qui va chercher le place_id et ensuite l'image
      FetchAndUpdateRestaurantPlaceIdJob.perform_later(restaurant_id)
      return
    end

    api_key = ENV['GOOGLE_PLACES_API_KEY']
    return unless api_key.present?

    # Récupérer les détails avec les photos (inclure width et height pour meilleure sélection)
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
      place_id: restaurant.place_id,
      fields: 'photos',
      key: api_key
    }
    
    response = HTTParty.get(url, query: params)
    return unless response.success?

    place_details = JSON.parse(response.body)
    return unless place_details['status'] == 'OK' && place_details['result']['photos'].present?

    photos = place_details['result']['photos']
    
    # Essayer la 2ème ou 3ème photo pour éviter les images de carte/génériques souvent en première position
    # La plupart du temps, les vraies photos du restaurant sont aux positions 1-3
    selected_index = photos.length > 1 ? 1 : 0  # Prendre la 2ème photo si disponible, sinon la 1ère
    selected_index = [selected_index, 2].min if photos.length > 2  # Max la 3ème photo
    
    selected_photo = photos[selected_index]
    photo_reference = selected_photo['photo_reference']
    
    # Générer l'URL de la photo (1200px pour une meilleure qualité)
    image_url = GooglePlacesSearchService.get_place_photo_url(photo_reference, 1200)
    
    restaurant.update(image_url: image_url) if image_url.present?
  rescue StandardError => e
    Rails.logger.error "Error fetching restaurant image: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
  end
end
