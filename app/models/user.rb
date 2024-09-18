class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :restaurants, dependent: :destroy
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # L'association pour les amitiés envoyées par l'utilisateur
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships, source: :friend

  # L'association pour les demandes d'amitié reçues
  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: 'friend_id', dependent: :destroy
  has_many :inverse_friends, through: :inverse_friendships, source: :user
end
