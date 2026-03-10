class AddReplaySupportToMatchesAndScoutingEntries < ActiveRecord::Migration[8.1]
  def change
    change_table :matches, bulk: true do |t|
      t.datetime :actual_time
      t.datetime :predicted_time
      t.datetime :post_result_time
      t.jsonb :videos, null: false, default: []
    end

    change_table :scouting_entries, bulk: true do |t|
      t.integer :scouting_mode, null: false, default: 0
      t.string :video_key
      t.string :video_type
    end

    remove_index :scouting_entries, name: "idx_scouting_entries_unique"
    add_index :scouting_entries,
              %i[event_id frc_team_id match_id user_id scouting_mode],
              unique: true,
              name: "idx_scouting_entries_unique"
  end
end
