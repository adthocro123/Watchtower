# frozen_string_literal: true

class NextScoutMatchService
  def initialize(event, reference_time: Time.current)
    @event = event
    @reference_time = reference_time
  end

  def next_match(after_match: nil)
    matches = ScoutableMatchesQuery.new(@event, reference_time: @reference_time).live
    matches = matches.select { |match| match_sorts_after?(match, after_match) } if after_match.present?

    coverage = MatchCoverageService.new(@event).coverage_for(matches)
    matches.find { |match| coverage.dig(match, :uncovered_team_count).to_i.positive? }
  end

  private

  def match_sorts_after?(candidate, current)
    current_values = sort_values(current)
    candidate_values = sort_values(candidate)
    candidate_values > current_values
  end

  def sort_values(match)
    [
      Match::COMP_LEVEL_ORDER.fetch(match.comp_level, 99),
      match.set_number.to_i,
      match.match_number.to_i,
      match.id.to_i
    ]
  end
end
