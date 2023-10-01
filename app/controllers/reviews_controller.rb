class ReviewsController < ApplicationController
  def index
    @reviews = Review.all
  end

  def show
    @review = Review.find_by(id: params[:id])
  end

  def new
    @review = Review.new
    @restaurant = Restaurant.find_by(id: params[:restaurant_id])
  end

  def create
    @review = Review.new(review_params(:title, :content, :rating))
    @restaurant = Restaurant.find_by(id: params[:restaurant_id])
    @review.restaurant = @restaurant
    if @review.save
      redirect_to restaurant_path(@restaurant)
    else
      render :new
    end
  end

private

  def review_params(*args)
    params.require(:review).permit(*args)
  end
end
