class MatchAlliance < ApplicationRecord
  # Associations
  belongs_to :match
  belongs_to :frc_team

  # Validations
  validates :match_id, uniqueness: { scope: :frc_team_id }
  validates :alliance_color, presence: true
  validates :station, presence: true
end
