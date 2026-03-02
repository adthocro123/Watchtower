class MatchSimulatorController < ApplicationController
  before_action :require_event!

  def new
    authorize :match_simulator, :new?

    @teams = FrcTeam.at_event(current_event).order(:team_number)
  end

  def create
    authorize :match_simulator, :create?

    red_team_ids = params[:red_team_ids] || []
    blue_team_ids = params[:blue_team_ids] || []

    @red_teams = FrcTeam.where(id: red_team_ids)
    @blue_teams = FrcTeam.where(id: blue_team_ids)

    @red_summaries = TeamEventSummary.where(event: current_event, frc_team_id: red_team_ids)
    @blue_summaries = TeamEventSummary.where(event: current_event, frc_team_id: blue_team_ids)

    @red_score = @red_summaries.sum(:avg_total_points)
    @blue_score = @blue_summaries.sum(:avg_total_points)

    @teams = FrcTeam.at_event(current_event).order(:team_number)

    respond_to do |format|
      format.html { render :new }
      format.turbo_stream
    end
  end
end
