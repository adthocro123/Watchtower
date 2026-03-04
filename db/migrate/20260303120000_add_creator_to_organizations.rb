class AddCreatorToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_reference :organizations, :creator, null: true, foreign_key: { to_table: :users }
  end
end
