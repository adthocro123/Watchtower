class CreateFrcTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :frc_teams do |t|
      t.integer :team_number
      t.string :nickname
      t.string :city
      t.string :state_prov
      t.string :country
      t.integer :rookie_year
      t.string :website

      t.timestamps
    end
    add_index :frc_teams, :team_number, unique: true
  end
end
