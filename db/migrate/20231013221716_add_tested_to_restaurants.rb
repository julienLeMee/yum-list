class AddTestedToRestaurants < ActiveRecord::Migration[7.0]
  def change
    add_column :restaurants, :tested, :boolean
  end
end
