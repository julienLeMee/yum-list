class FriendshipsController < ApplicationController
    before_action :authenticate_user!

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

      # Vérifie s'il existe déjà une demande d'ami dans les deux sens
      existing_friendship = Friendship.find_by(user_id: current_user.id, friend_id: @friend.id) ||
                            Friendship.find_by(user_id: @friend.id, friend_id: current_user.id)

      if existing_friendship.nil?
        # Création de la demande d'ami pour l'utilisateur actuel avec le statut "pending"
        current_user.friendships.create(friend: @friend, status: 'pending')

        # Envoi de l'email de demande d'ami
        FriendshipMailer.friend_request_email(current_user, @friend).deliver_now

        redirect_to dashboard_path, notice: "Friend request sent!"
      elsif existing_friendship.status == 'pending'
        # Si une demande est en attente, il ne se passe rien de plus
        redirect_to dashboard_path, alert: "A friend request is already pending."
      else
        # Si la relation existe et est déjà acceptée, on informe l'utilisateur
        redirect_to dashboard_path, alert: "You are already friends."
      end
    end

    def pending_requests
      # Liste les demandes d'amis reçues par l'utilisateur qui sont encore en attente
      @pending_requests = Friendship.where(friend: current_user, status: 'pending')
    end

    def accept
        friendship = Friendship.find(params[:id])

      if friendship && friendship.friend == current_user
        friendship.accept
        redirect_to dashboard_path, notice: "Friend request accepted!"
      else
        redirect_to dashboard_path, alert: "Friendship request not found."
      end
    end

    def reject
      friendship = Friendship.find(params[:id])

      if friendship && friendship.friend == current_user
        friendship.reject
        redirect_to dashboard_path, notice: "Friend request rejected!"
      else
        redirect_to dashboard_path, alert: "Friendship request not found."
      end
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
