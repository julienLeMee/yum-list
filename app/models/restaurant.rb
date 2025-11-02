class Restaurant < ApplicationRecord
  has_many :reviews, dependent: :destroy
  belongs_to :user
  validates :name, presence: true
  validates :address, presence: true
  validates :category, presence: true
  validates :tested, inclusion: { in: [true, false] }

  # Après création, essayer de récupérer le place_id si manquant (en arrière-plan uniquement)
  after_commit :fetch_place_id_if_needed, on: :create, if: :needs_place_id?

  private

  def needs_place_id?
    place_id.blank? || 
    place_id == "id place-id-input" || 
    place_id.start_with?("id ")
  end

  def fetch_place_id_if_needed
    # Chercher le place_id en arrière-plan si manquant (mais l'image sera récupérée directement dans le controller)
    FetchAndUpdateRestaurantPlaceIdJob.perform_later(id)
  end
end
