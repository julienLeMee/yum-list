# app/services/google_places_client.rb
# require 'net/http'
# require 'json'

# class GooglePlacesClient
#   BASE_URL = "https://maps.googleapis.com/maps/api/place/details/json".freeze
#   API_KEY = ENV['GOOGLE_API_KEY']  # Assurez-vous d'avoir configuré votre clé API

#   def self.details(place_id)
#     url = "#{BASE_URL}?place_id=#{place_id}&key=#{API_KEY}"
#     uri = URI(url)
#     response = Net::HTTP.get(uri)
#     JSON.parse(response)
#   end
# end
