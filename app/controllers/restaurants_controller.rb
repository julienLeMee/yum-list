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
    render json: { restaurants: @restaurants }
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
            Rails.logger.debug "Opening hours set: #{@restaurant.opening_hours}"
          else
            Rails.logger.warn("Opening hours are nil for restaurant: #{restaurant_params[:name]}")
            @restaurant.opening_hours = nil # ou un autre traitement
          end

          # Sauvegarder les modifications d'ouverture
          @restaurant.save # Assurez-vous de sauvegarder les horaires d'ouverture mis à jour
        else
          Rails.logger.error "Error fetching opening hours for place_id: #{@restaurant.place_id}"
        end
      end
      redirect_to restaurant_path(@restaurant)
    else
      render :new # Au lieu de rediriger, vous pourriez vouloir rester sur la page de création
    end
  end

  def edit
    @restaurant = Restaurant.find(params[:id])
  end

  def update
    @restaurant = Restaurant.find(params[:id])
    if @restaurant.update(restaurant_params)
      if @restaurant.place_id.present?
        place_details = get_place_details(@restaurant.place_id)
        Rails.logger.debug "Place Details: #{place_details.inspect}"

        if place_details["status"] == "OK"
          @opening_hours = place_details.dig("result", "opening_hours", "weekday_text")
          Rails.logger.debug "Opening Hours: #{@opening_hours.inspect}"
        else
          Rails.logger.error "Error fetching place details: #{place_details['status']}"
          @opening_hours = []
        end
      end
      redirect_to restaurant_path(@restaurant, opening_hours: @opening_hours) # <-- Pass the opening_hours here
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
    params.require(:restaurant).permit(:name, :address, :description, :category, :tested, :place_id, :opening_hours, :rating, :google_place_id)
  end

  def get_place_details(place_id)
    api_key = ENV['GOOGLE_PLACES_API_KEY']
    url = URI("https://maps.googleapis.com/maps/api/place/details/json?place_id=#{place_id}&fields=name,opening_hours,formatted_address&key=#{api_key}")
    response = Net::HTTP.get(url)
    result = JSON.parse(response)
    Rails.logger.debug "Google Place Details Response: #{result.inspect}"
    result
  end
end
