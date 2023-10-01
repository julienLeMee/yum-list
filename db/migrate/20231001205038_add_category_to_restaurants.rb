class AddCategoryToRestaurants < ActiveRecord::Migration[7.0]
  def change
    add_column :restaurants, :category, :string
  end
end
