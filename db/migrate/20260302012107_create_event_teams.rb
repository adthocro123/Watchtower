class CreateEventTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :event_teams do |t|
      t.references :event, null: false, foreign_key: true
      t.references :frc_team, null: false, foreign_key: true

      t.timestamps
    end

    add_index :event_teams, %i[event_id frc_team_id], unique: true
  end
end
