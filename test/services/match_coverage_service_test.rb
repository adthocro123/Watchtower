require "test_helper"

class MatchCoverageServiceTest < ActiveSupport::TestCase
  test "coverage_for_match counts covered and uncovered teams" do
    coverage = MatchCoverageService.new(events(:championship)).coverage_for_match(matches(:qm4))

    assert_equal 1, coverage[:covered_team_count]
    assert_equal 5, coverage[:uncovered_team_count]
    assert_equal [ 254 ], coverage[:teams].select { |team| team[:covered] }.map { |team| team[:frc_team].team_number }
  end

  test "coverage ignores flagged and rejected entries" do
    scouting_entries(:entry_qm4_254_live).update!(status: :flagged)

    ScoutingEntry.create!(
      user: users(:lead_user),
      match: matches(:qm4),
      frc_team: frc_teams(:team_6328),
      event: events(:championship),
      status: :rejected,
      data: {},
      client_uuid: "coverage-ignore-#{SecureRandom.hex(8)}"
    )

    coverage = MatchCoverageService.new(events(:championship)).coverage_for_match(matches(:qm4))

    assert_equal 0, coverage[:covered_team_count]
    assert_equal 6, coverage[:uncovered_team_count]
  end
end
