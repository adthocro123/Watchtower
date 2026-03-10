# frozen_string_literal: true

class MatchCoverageService
  def initialize(event)
    @event = event
  end

  def coverage_for(matches)
    matches.index_with { |match| build_match_coverage(match, team_counts.fetch(match.id, {})) }
  end

  def coverage_for_match(match)
    return if match.blank?

    coverage_for([ match ])[match]
  end

  private

  def team_counts
    @team_counts ||= @event.scouting_entries
                          .submitted
                          .where.not(match_id: nil)
                          .group(:match_id, :frc_team_id)
                          .count
                          .each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |((match_id, team_id), count), hash|
      hash[match_id][team_id] = count
    end
  end

  def build_match_coverage(match, counts)
    teams = match.match_alliances.sort_by { |alliance| [ alliance.alliance_color, alliance.station ] }.map do |alliance|
      entry_count = counts.fetch(alliance.frc_team_id, 0)

      {
        frc_team: alliance.frc_team,
        alliance_color: alliance.alliance_color,
        station: alliance.station,
        entry_count: entry_count,
        covered: entry_count.positive?
      }
    end

    {
      teams: teams,
      covered_team_count: teams.count { |team| team[:covered] },
      uncovered_team_count: teams.count { |team| !team[:covered] }
    }
  end
end
