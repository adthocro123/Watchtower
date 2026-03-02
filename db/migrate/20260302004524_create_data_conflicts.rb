class CreateDataConflicts < ActiveRecord::Migration[8.1]
  def change
    create_table :data_conflicts do |t|
      t.references :event, null: false, foreign_key: true
      t.references :frc_team, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.string :field_name, null: false
      t.jsonb :values, null: false, default: {}
      t.boolean :resolved, null: false, default: false
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.string :resolution_value

      t.timestamps
    end

    add_index :data_conflicts, %i[event_id frc_team_id match_id field_name], unique: true, name: "idx_data_conflicts_unique"
  end
end
