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
    @user = @restaurant.user
    @editable = current_user == @user
    @reviews = @restaurant.reviews
  end

  def new
    @restaurant = Restaurant.new
  end

  def create
    @restaurant = current_user.restaurants.new(restaurant_params)
    if @restaurant.save
      redirect_to restaurant_path(@restaurant)
    else
      render :new
    end
  end

  def edit
    @restaurant = Restaurant.find(params[:id])
  end

  def update
    @restaurant = Restaurant.find(params[:id])
    if @restaurant.update(restaurant_params)
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
    params.require(:restaurant).permit(:name, :address, :category, :description, :tested, :rating)
  end
end
