class FriendshipsController < ApplicationController
    before_action :authenticate_user!

    def new
        # Rien à faire ici pour l'instant
      end

      def create
        email = params[:email]
        @friend = User.find_by(email: email)

        if @friend.nil?
          redirect_to new_friendship_path, alert: "User with email #{email} not found."
          return
        end

        if current_user == @friend
          redirect_to new_friendship_path, alert: "You cannot friend yourself."
          return
        end

        existing_friendship = Friendship.find_by(user_id: current_user.id, friend_id: @friend.id)
        if existing_friendship.nil?
          current_user.friendships.create(friend: @friend, status: 'pending')
          @friend.friendships.create(user: current_user, status: 'pending')
          redirect_to dashboard_path, notice: "Friend request sent!"
        else
          redirect_to new_friendship_path, alert: "Friend request already sent or you are already friends."
        end
      end

    def update
      friendship = Friendship.find(params[:id])
      friendship.update(status: 'accepted')
      redirect_to dashboard_path, notice: "Friend request accepted!"
    end

    def destroy
      friendship = Friendship.find(params[:id])
      friendship.destroy
      redirect_to dashboard_path, notice: "Friend removed!"
    end
  end
