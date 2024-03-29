class RestaurantsController < ApplicationController
  def index
    @restaurants = current_user.restaurants
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
