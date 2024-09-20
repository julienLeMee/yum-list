class Notification < ApplicationRecord
    belongs_to :user

    # Pour que Noticed fonctionne correctement
    validates :type, presence: true
    validates :params, presence: true
  end
