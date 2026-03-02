class CreateScoutingEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :scouting_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :match, null: true, foreign_key: true
      t.references :frc_team, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.jsonb :data, null: false, default: {}
      t.text :notes
      t.string :photo_url
      t.integer :status, null: false, default: 0
      t.string :client_uuid

      t.timestamps
    end

    add_index :scouting_entries, :client_uuid, unique: true
    add_index :scouting_entries, :data, using: :gin
    add_index :scouting_entries, %i[event_id frc_team_id match_id user_id], unique: true, name: "idx_scouting_entries_unique"
  end
end
