# frozen_string_literal: true

class MatchSimulatorService
  ITERATIONS = 1000
  DEFAULT_STDDEV = 5.0

  def initialize(event)
    @event = event
    @aggregation_service = AggregationService.new(event)
  end

  # Runs a Monte Carlo simulation for a hypothetical match.
  #
  # @param red_teams [Array<FrcTeam>] 3 teams on the red alliance
  # @param blue_teams [Array<FrcTeam>] 3 teams on the blue alliance
  # @return [Hash] simulation results
  def simulate(red_teams, blue_teams)
    red_stats = red_teams.map { |t| team_stats(t) }
    blue_stats = blue_teams.map { |t| team_stats(t) }

    red_wins = 0
    blue_wins = 0
    red_scores = []
    blue_scores = []

    ITERATIONS.times do
      red_score = red_stats.sum { |s| sample_score(s[:avg], s[:stddev]) }
      blue_score = blue_stats.sum { |s| sample_score(s[:avg], s[:stddev]) }

      red_scores << red_score
      blue_scores << blue_score

      if red_score > blue_score
        red_wins += 1
      elsif blue_score > red_score
        blue_wins += 1
      else
        # Tie: half-credit to each
        red_wins += 0.5
        blue_wins += 0.5
      end
    end

    red_avg = (red_scores.sum / ITERATIONS.to_f).round(2)
    blue_avg = (blue_scores.sum / ITERATIONS.to_f).round(2)

    {
      red_avg: red_avg,
      blue_avg: blue_avg,
      red_win_pct: (red_wins / ITERATIONS.to_f * 100).round(1),
      blue_win_pct: (blue_wins / ITERATIONS.to_f * 100).round(1),
      margin_of_victory: (red_avg - blue_avg).abs.round(2)
    }
  end

  private

  def team_stats(frc_team)
    agg = @aggregation_service.aggregate_team(frc_team)
    {
      avg: agg[:avg_total_points],
      stddev: agg[:stddev_total_points].positive? ? agg[:stddev_total_points] : DEFAULT_STDDEV
    }
  end

  # Samples from a normal distribution using the Box-Muller transform.
  # Clamps the result to a minimum of 0 (no negative scores).
  def sample_score(mean, stddev)
    u1 = rand
    u2 = rand
    z = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math::PI * u2)
    [mean + z * stddev, 0].max
  end
end
