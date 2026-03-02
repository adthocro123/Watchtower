class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :team_number, :integer
    add_column :users, :avatar_url, :string
  end
end
