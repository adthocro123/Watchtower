class Match < ApplicationRecord
  # Associations
  belongs_to :event
  has_many :match_alliances, dependent: :destroy
  has_many :frc_teams, through: :match_alliances
  has_many :scouting_entries, dependent: :destroy
  has_many :predictions, dependent: :destroy

  # Scopes
  COMP_LEVEL_ORDER = { "qm" => 0, "qf" => 1, "sf" => 2, "f" => 3 }.freeze

  scope :with_scores, -> { where.not(red_score: nil, blue_score: nil) }

  scope :ordered, -> {
    order(
      Arel.sql(
        "CASE comp_level " \
        "WHEN 'qm' THEN 0 " \
        "WHEN 'qf' THEN 1 " \
        "WHEN 'sf' THEN 2 " \
        "WHEN 'f'  THEN 3 " \
        "ELSE 4 END ASC, " \
        "set_number ASC, match_number ASC"
      )
    )
  }

  # Returns a human-readable display name:
  #   qm  -> "Q1"
  #   qf  -> "QF1-1"
  #   sf  -> "SF1-1"
  #   f   -> "F1"
  def display_name
    case comp_level
    when "qm"
      "Q#{match_number}"
    when "qf"
      "QF#{set_number}-#{match_number}"
    when "sf"
      "SF#{set_number}-#{match_number}"
    when "f"
      "F#{match_number}"
    else
      "#{comp_level&.upcase}#{match_number}"
    end
  end
end
