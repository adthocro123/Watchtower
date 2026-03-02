class TeamEventSummary < ApplicationRecord
  self.table_name = "team_event_summaries"

  # This is a read-only model backed by a materialized view
  def readonly?
    true
  end

  # Associations
  belongs_to :event
  belongs_to :frc_team

  # Refreshes the materialized view concurrently.
  # The CONCURRENTLY option requires a unique index on the view,
  # which exists as idx_team_event_summaries(event_id, frc_team_id).
  def self.refresh!
    connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY #{table_name}")
  end
end
