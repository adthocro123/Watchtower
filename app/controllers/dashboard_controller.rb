class DashboardController < ApplicationController
  skip_after_action :pundit_verify

  def index
    authorize :dashboard, :index?

    if current_event
      @event = current_event
      @team_summaries = TeamEventSummary.where(event: @event).order(avg_total_points: :desc)
      @recent_entries = ScoutingEntry.where(event: @event).order(created_at: :desc).limit(10)
      @unresolved_conflicts_count = DataConflict.where(event: @event).unresolved.count
    else
      @events = Event.current_year.order(start_date: :asc)
    end
  end
end
