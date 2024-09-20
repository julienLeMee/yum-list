class Friendship < ApplicationRecord
    belongs_to :user
    belongs_to :friend, class_name: 'User'

    validates :user_id, presence: true
    validates :friend_id, presence: true
    validates :status, presence: true

    enum status: { pending: 'pending', accepted: 'accepted', rejected: 'rejected' }

    # Méthode pour accepter une demande d'amitié
    def accept
        if status == 'pending'
            update(status: 'accepted')
            # Crée une relation réciproque seulement si elle n'existe pas déjà
            Friendship.find_or_create_by(user_id: friend_id, friend_id: user_id) do |f|
                f.status = 'accepted'
            end
        else
            Rails.logger.warn("Attempted to accept a friendship that is not pending: #{self.inspect}")
            false
        end
    end



    # Méthode pour refuser une demande d'amitié
    def reject
      update(status: 'rejected')
      # Rejette aussi la relation réciproque si elle existe
      reciprocal.update(status: 'rejected') if reciprocal.present?
    end

    # Méthode pour trouver la relation inverse
    def reciprocal
      Friendship.find_by(user_id: friend_id, friend_id: user_id)
    end
  end
