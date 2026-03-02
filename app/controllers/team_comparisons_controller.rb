class TeamComparisonsController < ApplicationController
  before_action :require_event!
  skip_after_action :pundit_verify

  def show
    authorize :team_comparison, :show?

    # Support both comma-separated ?teams=1,2,3 and checkbox array ?team_ids[]=1&team_ids[]=2
    team_ids = if params[:team_ids].present?
      Array(params[:team_ids]).map(&:to_i).reject(&:zero?)
    else
      (params[:teams] || "").split(",").map(&:to_i).reject(&:zero?)
    end
    team_ids = team_ids.first(6) # Limit to 6 teams
    @teams = FrcTeam.where(id: team_ids).order(:team_number)
    @all_teams = FrcTeam.at_event(current_event).order(:team_number)

    @summaries = {}
    @entries_by_team = {}
    @pit_data = {}

    @teams.each do |team|
      @summaries[team.id] = TeamEventSummary.find_by(event: current_event, frc_team: team)
      @entries_by_team[team.id] = ScoutingEntry.where(event: current_event, frc_team: team)
                                               .includes(:match)
                                               .order(created_at: :asc)
      @pit_data[team.id] = PitScoutingEntry.find_by(event: current_event, frc_team: team)
    end
  end
end
