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

    def friends
      @friends = current_user.friends
    end

    def friend_restaurants
        @friend = User.find(params[:id])

        unless current_user.friends.include?(@friend) || current_user.inverse_friends.include?(@friend)
          Rails.logger.debug "User #{current_user.id} is not friends with #{@friend.id}. Redirecting to dashboard."
          redirect_to dashboard_path, alert: "You are not friends with this user."
          return
        end

        @restaurants = @friend.restaurants
    end
end
