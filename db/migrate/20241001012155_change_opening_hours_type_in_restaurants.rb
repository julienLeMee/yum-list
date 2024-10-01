class ChangeOpeningHoursTypeInRestaurants < ActiveRecord::Migration[7.0]
    def change
        change_column :restaurants, :opening_hours, :text
    end
end
