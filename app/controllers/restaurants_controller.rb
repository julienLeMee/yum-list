require 'net/http'
require 'json'

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
      @restaurants = @user.restaurants
      @editable = false
      @debug_message = "Affichage des restaurants d'un ami"
      logger.debug "Affichage des restaurants d'un ami"
    else
      # Affichage des restaurants de l'utilisateur actuel
      @user = current_user
      if params[:query].present?
        @restaurants = @user.restaurants.where('name LIKE ? OR category LIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
      else
        @restaurants = @user.restaurants
      end
      @editable = true
      @debug_message = "Affichage des restaurants de l'utilisateur actuel"
      logger.debug "Affichage des restaurants de l'utilisateur actuel"
    end
  end

  def categories
    @categories = current_user.restaurants.select(:category).distinct.pluck(:category)
  end

  def tested_restaurants
    @restaurants = current_user.restaurants.where(tested: true)
  end

  def untested_restaurants
    @restaurants = current_user.restaurants.where(tested: false)
  end

  def restaurant_list
    @restaurants = current_user.restaurants

    render json: { restaurants: @restaurants.as_json(only: [:id, :name, :latitude, :longitude, :category]) }
  end

  def show
    @restaurant = Restaurant.find_by(id: params[:id])
    if @restaurant
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
      if @restaurant.place_id.present?
        place_details = get_place_details(@restaurant.place_id)
        Rails.logger.debug "Place Details: #{place_details.inspect}"

        if place_details['status'] == 'OK' && place_details['result']
          opening_hours = place_details['result']['opening_hours']

          if opening_hours
            hours_text = opening_hours['weekday_text'] # ou un autre format selon vos besoins
            @restaurant.opening_hours = hours_text.to_json # stockez-les comme JSON
          else
            @restaurant.opening_hours = nil
          end

          # ** Ajoutez ces lignes pour enregistrer la latitude et la longitude **
          @restaurant.latitude = place_details['result']['geometry']['location']['lat']
          @restaurant.longitude = place_details['result']['geometry']['location']['lng']

          # Sauvegarder les modifications d'ouverture et les coordonnées
          @restaurant.save # Assurez-vous de sauvegarder les horaires d'ouverture et les coordonnées mises à jour
        end
      end
      redirect_to restaurant_path(@restaurant)
    else
      render :new
    end
  end

  def edit
    @restaurant = Restaurant.find(params[:id])
  end

  def update
    logger.debug "Received params: #{params.inspect}"
    @restaurant = Restaurant.find(params[:id])
    if @restaurant.update(restaurant_params)
      if @restaurant.place_id.present?
        place_details = get_place_details(@restaurant.place_id)
        Rails.logger.debug "See place Details: #{place_details.inspect}"

        if place_details["status"] == "OK"

          @opening_hours = place_details.dig("result", "opening_hours", "weekday_text")

          # Mettez à jour tous les attributs en une seule fois
          @restaurant.update(
            opening_hours: @opening_hours.to_json,
            latitude: place_details['result']['geometry']['location']['lat'],
            longitude: place_details['result']['geometry']['location']['lng']
          )
        else
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
    url = URI("https://maps.googleapis.com/maps/api/place/details/json?place_id=#{place_id}&fields=name,opening_hours,formatted_address,geometry&key=#{api_key}")
    response = Net::HTTP.get(url)
    result = JSON.parse(response)
    Rails.logger.debug "Google Place Details Response: #{result.inspect}"

    # Vérifiez si geometry est présent
    if result['status'] == 'OK' && result['result'].key?('geometry')
      return result
    else
      Rails.logger.warn "Place details not found for place_id: #{place_id}"
      return nil
    end
  end
end
