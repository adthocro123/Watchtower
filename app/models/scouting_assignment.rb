class ScoutingAssignment < ApplicationRecord
  # Associations
  belongs_to :event
  belongs_to :user
  belongs_to :match
  belongs_to :frc_team, optional: true

  # Validations
  validates :event_id, uniqueness: { scope: %i[user_id match_id] }
  validates :alliance_color, inclusion: { in: %w[red blue] }, allow_nil: true
  validates :station, inclusion: { in: 1..3 }, allow_nil: true
  validate :match_belongs_to_event

  # Scopes
  scope :for_event, ->(event) { where(event_id: event.id) }
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :ordered, -> { includes(:match).joins(:match).merge(Match.ordered) }

  private

  def match_belongs_to_event
    return if match.blank? || event.blank?
    return if match.event_id == event_id

    errors.add(:match_id, "must belong to the selected event")
  end
end
