class DropReports < ActiveRecord::Migration[8.1]
  def change
    drop_table :reports do |t|
      t.string :name, null: false
      t.jsonb :config, default: {}, null: false
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
