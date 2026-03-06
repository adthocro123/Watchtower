class CreateScoutingAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :scouting_assignments do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.references :frc_team, foreign_key: true
      t.string :alliance_color
      t.integer :station
      t.text :notes
      t.datetime :notified_5_at
      t.datetime :notified_2_at
      t.datetime :notified_1_at

      t.timestamps
    end

    add_index :scouting_assignments, [ :event_id, :user_id, :match_id ],
              unique: true,
              name: "idx_scouting_assignments_unique"
    add_index :scouting_assignments, [ :event_id, :match_id ]
  end
end
