class AddPlaceIdToRestaurants < ActiveRecord::Migration[7.0]
  def change
    add_column :restaurants, :place_id, :string
  end
end
