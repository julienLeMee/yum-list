class AddImageUrlToRestaurants < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :image_url, :string
  end
end
