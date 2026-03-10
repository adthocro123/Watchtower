class AddScoresToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :red_score, :integer
    add_column :matches, :blue_score, :integer
  end
end
