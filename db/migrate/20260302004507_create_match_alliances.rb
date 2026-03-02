class CreateMatchAlliances < ActiveRecord::Migration[8.1]
  def change
    create_table :match_alliances do |t|
      t.references :match, null: false, foreign_key: true
      t.references :frc_team, null: false, foreign_key: true
      t.string :alliance_color, null: false
      t.integer :station, null: false

      t.timestamps
    end

    add_index :match_alliances, %i[match_id frc_team_id], unique: true
    add_index :match_alliances, %i[match_id alliance_color station], unique: true, name: "idx_match_alliances_unique_station"
  end
end
