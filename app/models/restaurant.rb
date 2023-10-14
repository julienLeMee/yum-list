class Restaurant < ApplicationRecord
  has_many :reviews, dependent: :destroy
  belongs_to :user
  validates :name, presence: true
  validates :category, presence: true
  validates :tested, inclusion: { in: [true, false] }
end
