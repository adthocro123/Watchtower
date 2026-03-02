class CreatePickLists < ActiveRecord::Migration[8.1]
  def change
    create_table :pick_lists do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.jsonb :entries

      t.timestamps
    end
  end
end
