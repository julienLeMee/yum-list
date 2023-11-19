# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:show, :logout]

  def show
    @user = current_user
    @restaurants = @user.restaurants
  end

  def logout
    sign_out current_user
    redirect_to root_path, notice: 'Vous avez été déconnecté avec succès.'
  end
end
