class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :tba_key
      t.string :name
      t.integer :event_type
      t.string :city
      t.string :state_prov
      t.string :country
      t.date :start_date
      t.date :end_date
      t.integer :year
      t.integer :week

      t.timestamps
    end
    add_index :events, :tba_key, unique: true
  end
end
