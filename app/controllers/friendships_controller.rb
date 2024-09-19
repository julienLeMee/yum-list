class FriendshipsController < ApplicationController
    before_action :authenticate_user!

    # app/controllers/friendships_controller.rb
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

      # Assure-toi que les paramètres ne sont pas nil
      FriendshipMailer.friend_request_email(current_user, @friend).deliver_now

      redirect_to dashboard_path, notice: "Friend request sent!"
    else
      redirect_to new_friendship_path, alert: "Friend request already sent or you are already friends."
    end
  end


    def pending_requests
      @pending_requests = current_user.received_friend_requests
    end

    def accept
      friendship = Friendship.find(params[:id])
      friendship.update(status: 'accepted')
      redirect_to dashboard_path, notice: "Friend request accepted!"
    end

    def reject
      friendship = Friendship.find(params[:id])
      friendship.destroy
      redirect_to dashboard_path, notice: "Friend request rejected!"
    end

    def update
      friendship = Friendship.find(params[:id])
      friendship.update(status: 'accepted')
      redirect_to dashboard_path, notice: "Friend request accepted!"
    end

    def destroy
      friendship = Friendship.find(params[:id])
      if friendship
        friendship.destroy
        redirect_to friends_path, status: :see_other, notice: "Friend removed!"
      else
        redirect_to friends_path, status: :see_other, alert: "Friend not found."
      end
    end

    private

    def friendship_params
      params.require(:friendship).permit(:email)
    end
  end
