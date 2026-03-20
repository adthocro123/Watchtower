require "test_helper"

class TeamEventSummaryTest < ActiveSupport::TestCase
  # TeamEventSummary is backed by a materialized view, not a regular table.

  test "uses team_event_summaries table" do
    assert_equal "team_event_summaries", TeamEventSummary.table_name
  end

  test "readonly? returns true" do
    summary = TeamEventSummary.allocate
    assert summary.readonly?
  end

  test "responds to event association" do
    assert TeamEventSummary.reflect_on_association(:event).present?
    assert_equal :belongs_to, TeamEventSummary.reflect_on_association(:event).macro
  end

  test "responds to frc_team association" do
    assert TeamEventSummary.reflect_on_association(:frc_team).present?
    assert_equal :belongs_to, TeamEventSummary.reflect_on_association(:frc_team).macro
  end

  test "responds to refresh!" do
    assert_respond_to TeamEventSummary, :refresh!
  end

  test "exposes average defense rating" do
    TeamEventSummary.refresh!

    summary = TeamEventSummary.find_by!(event: events(:championship), frc_team: frc_teams(:team_254))
    assert_in_delta 4.67, summary.avg_defense_rating.to_f, 0.01
  end
end
