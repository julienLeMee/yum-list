class FixFriendshipForeignKey < ActiveRecord::Migration[7.0]
    def change
      # Drop the existing foreign key constraint
      remove_foreign_key :friendships, :friends

      # Add the correct foreign key constraint
      add_foreign_key :friendships, :users, column: :friend_id
    end
  end
