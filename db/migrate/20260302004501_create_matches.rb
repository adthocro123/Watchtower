class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.string :tba_key
      t.references :event, null: false, foreign_key: true
      t.string :comp_level
      t.integer :set_number
      t.integer :match_number
      t.datetime :scheduled_time

      t.timestamps
    end
    add_index :matches, :tba_key, unique: true
  end
end
