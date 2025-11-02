require 'httparty'

class GooglePlacesSearchService
  BASE_URL = "https://maps.googleapis.com/maps/api/place".freeze

  def self.find_place_id(restaurant_name, address = nil)
    api_key = ENV['GOOGLE_PLACES_API_KEY']
    return nil unless api_key.present?

    # Construire la requête de recherche
    query = restaurant_name
    query += " #{address}" if address.present?
    # Ajouter "Montreal" par défaut si pas d'adresse spécifique
    query += " Montreal" unless address.present? && address.downcase.include?('montreal')

    # Essayer d'abord avec Text Search API
    place_id = find_with_text_search(query, api_key)
    return place_id if place_id.present?

    # Si ça échoue, essayer avec Nearby Search (nécessite des coordonnées)
    # Cette méthode nécessiterait latitude/longitude, on la skip pour l'instant
    nil
  rescue StandardError => e
    Rails.logger.error "Error searching for place: #{e.message}"
    Rails.logger.error e.backtrace.first(3).join("\n")
    nil
  end

  private

  def self.find_with_text_search(query, api_key)
    url = "#{BASE_URL}/textsearch/json"
    params = {
      query: query,
      key: api_key
    }

    response = HTTParty.get(url, query: params)
    return nil unless response.success?

    result = JSON.parse(response.body)
    
    if result['status'] == 'OK' && result['results'].present?
      # Prendre le premier résultat (le plus pertinent)
      result['results'].first['place_id']
    elsif result['status'] == 'REQUEST_DENIED'
      Rails.logger.error "API key has restrictions that prevent server-side calls. Error: #{result['error_message']}"
      Rails.logger.error "Solution: Create a server API key without referer restrictions in Google Cloud Console"
      nil
    else
      Rails.logger.warn "No place found for: #{query} - Status: #{result['status']}, Error: #{result['error_message']}"
      nil
    end
  end

  def self.get_place_photo_url(photo_reference, max_width = 800)
    api_key = ENV['GOOGLE_PLACES_API_KEY']
    return nil unless api_key.present?
    
    "https://maps.googleapis.com/maps/api/place/photo?maxwidth=#{max_width}&photo_reference=#{photo_reference}&key=#{api_key}"
  end
end

