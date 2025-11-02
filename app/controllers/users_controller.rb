class UsersController < ApplicationController
    before_action :authenticate_user!, only: [:show, :edit, :update, :logout, :notifications, :mark_notification_as_read]
    before_action :set_user, only: [:show, :edit, :update]
    before_action :set_pending_friend_requests

    def show
      @restaurants = @user.restaurants
    end

    def edit
      # @user est défini par set_user (qui utilise current_user)
    end

    def update
        # Rails.logger.debug "User params: #{user_params.inspect}"

        if @user.update(user_params)
          redirect_to @user, notice: 'Your profile has been updated successfully.'
        else
        #   Rails.logger.debug "Update failed: #{@user.errors.full_messages}"
          render :edit
        end
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
        # Rails.logger.debug "User #{current_user.id} is not friends with #{@friend.id}. Redirecting to dashboard."
        redirect_to dashboard_path, alert: "You are not friends with this user."
        return
      end

      @restaurants = @friend.restaurants
    end

    def notifications
      @notifications = current_user.noticed_notifications
      @unread_count = current_user.unread_notifications_count
    end

    def mark_notification_as_read
      notification = Noticed::Notification.find(params[:id])
      if notification.recipient == current_user
        notification.mark_as_read!
        redirect_to notifications_path, notice: "Notification marquée comme lue."
      else
        redirect_to notifications_path, alert: "Vous n'avez pas accès à cette notification."
      end
    end

    private

    # Assigner l'utilisateur courant
    def set_user
      @user = current_user
    end

    def set_pending_friend_requests
        if current_user
          pending_requests = Friendship.where(friend: current_user, status: :pending)
        #   Rails.logger.debug "Pending friend requests count: #{pending_requests.count}, requests: #{pending_requests.inspect}"
          @pending_friend_requests = pending_requests.count
        end
      end

    def user_params
        if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
          params.require(:user).permit(:name, :email)
        else
          params.require(:user).permit(:name, :email, :password, :password_confirmation)
        end
      end
  end
