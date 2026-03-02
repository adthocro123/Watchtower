class EventTeam < ApplicationRecord
  belongs_to :event
  belongs_to :frc_team

  validates :frc_team_id, uniqueness: { scope: :event_id }
end
