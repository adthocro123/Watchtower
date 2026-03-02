class TeamsController < ApplicationController
  before_action :require_event!

  def index
    @teams = policy_scope(FrcTeam)
               .at_event(current_event)
               .order(:team_number)

    @summaries = TeamEventSummary.where(event: current_event).index_by(&:frc_team_id)
    @statbotics_epa = fetch_statbotics_epa_for_teams(@teams)
  end

  def show
    @team = FrcTeam.find(params[:id])
    authorize @team, policy_class: FrcTeamPolicy

    @entries = ScoutingEntry.where(event: current_event, frc_team: @team)
                            .includes(:match, :user)
                            .order(created_at: :desc)

    @summary = TeamEventSummary.find_by(event: current_event, frc_team: @team)
    @matches = @team.matches.where(event: current_event).ordered
    @pit_entry = PitScoutingEntry.find_by(event: current_event, frc_team: @team)
    @epa = fetch_team_epa(@team)
  end

  private

  def fetch_team_epa(team)
    return nil unless current_event.year.present?

    client = StatboticsClient.new
    data = client.team_year(team.team_number, current_event.year)
    return nil unless data.is_a?(Hash)

    epa = data.dig("epa", "total_points")
    record = data["record"]
    return nil unless epa

    {
      epa_mean: epa["mean"].to_f.round(1),
      epa_sd: epa["sd"].to_f.round(1),
      epa_rank: data.dig("epa", "ranks", "total", "rank"),
      epa_percentile: data.dig("epa", "ranks", "total", "percentile"),
      record: record ? "#{record['wins']}-#{record['losses']}-#{record['ties']}" : nil,
      winrate: record ? (record["winrate"].to_f * 100).round(0) : nil
    }
  rescue StandardError => e
    Rails.logger.warn("[TeamsController] Statbotics EPA fetch failed for team #{team.team_number}: #{e.message}")
    nil
  end

  def fetch_statbotics_epa_for_teams(teams)
    return {} unless current_event.year.present?

    client = StatboticsClient.new
    teams.each_with_object({}) do |team, hash|
      data = client.team_year(team.team_number, current_event.year)
      next unless data.is_a?(Hash)

      epa = data.dig("epa", "total_points")
      record = data["record"]
      next unless epa

      hash[team.id] = {
        epa_mean: epa["mean"].to_f.round(1),
        record: record ? "#{record['wins']}-#{record['losses']}-#{record['ties']}" : nil,
        winrate: record ? (record["winrate"].to_f * 100).round(0) : nil
      }
    rescue StandardError
      next
    end
  end
end
