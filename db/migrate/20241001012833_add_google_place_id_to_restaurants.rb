class AddGooglePlaceIdToRestaurants < ActiveRecord::Migration[7.0]
  def change
    add_column :restaurants, :google_place_id, :string
  end
end
