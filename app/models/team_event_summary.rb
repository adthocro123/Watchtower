class TeamEventSummary < ApplicationRecord
  self.table_name = "team_event_summaries"

  # This is a read-only model backed by a materialized view
  def readonly?
    true
  end

  # Associations
  belongs_to :event
  belongs_to :frc_team

  # Refreshes the materialized view.
  # Uses CONCURRENTLY when possible (requires a unique index and prior population).
  # Falls back to a blocking refresh on the first run when the view is unpopulated.
  def self.refresh!
    connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY #{table_name}")
  rescue ActiveRecord::StatementInvalid => e
    raise unless e.message.include?("has not been populated") || e.message.include?("is not populated")

    connection.execute("REFRESH MATERIALIZED VIEW #{table_name}")
  end
end
