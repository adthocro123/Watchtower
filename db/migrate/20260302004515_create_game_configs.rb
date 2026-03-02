class CreateGameConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :game_configs do |t|
      t.integer :year, null: false
      t.string :game_name, null: false
      t.jsonb :config, null: false, default: {}
      t.boolean :active, null: false, default: false

      t.timestamps
    end

    add_index :game_configs, :year, unique: true
    add_index :game_configs, :active
  end
end
