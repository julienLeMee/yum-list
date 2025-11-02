class User < ApplicationRecord
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    has_many :restaurants, dependent: :destroy
    has_many :push_subscriptions, dependent: :destroy
    
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable

    # L'association pour les amitiés envoyées par l'utilisateur
    has_many :friendships, dependent: :destroy
    has_many :friends, through: :friendships, source: :friend

    # L'association pour les demandes d'amitié reçues
    has_many :inverse_friendships, class_name: 'Friendship', foreign_key: 'friend_id', dependent: :destroy
    has_many :received_friend_requests, -> { where(status: 'pending') }, class_name: 'Friendship', foreign_key: 'friend_id'
    has_many :inverse_friends, through: :inverse_friendships, source: :user

    # Méthode pour obtenir les demandes d'ami reçues
    def received_friend_requests
        inverse_friendships.where(status: 'pending')
    end

    # Méthode pour obtenir tous les amis acceptés (dans les deux sens)
    def accepted_friends
        # Amis acceptés via les friendships que j'ai initiées
        friend_ids_from_friendships = friendships.where(status: 'accepted').pluck(:friend_id)
        
        # Amis acceptés via les friendships que j'ai reçues
        friend_ids_from_inverse = inverse_friendships.where(status: 'accepted').pluck(:user_id)
        
        # Combiner les deux listes et retirer les doublons
        all_friend_ids = (friend_ids_from_friendships + friend_ids_from_inverse).uniq
        
        User.where(id: all_friend_ids)
    end

    # Association pour les notifications Noticed
    def noticed_notifications
        Noticed::Notification.where(recipient: self).order(created_at: :desc)
    end

    # Méthode pour obtenir les notifications non lues
    def unread_notifications_count
        noticed_notifications.where(read_at: nil).count
    end
  end
