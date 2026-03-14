require "test_helper"

class ScoutableMatchesQueryTest < ActiveSupport::TestCase
  test "live returns only future matches" do
    matches = ScoutableMatchesQuery.new(events(:championship), reference_time: Time.zone.parse("2026-04-15 10:30:00")).live

    assert_equal [ matches(:qm2), matches(:qm3) ], matches
  end

  test "normal returns all qualification matches including ones already played" do
    matches = ScoutableMatchesQuery.new(events(:championship), reference_time: Time.zone.parse("2026-04-15 10:30:00")).normal

    assert_equal [ matches(:qm1), matches(:qm2), matches(:qm3), matches(:qm4) ], matches
  end

  test "normal still returns qualification matches after the event has ended" do
    matches = ScoutableMatchesQuery.new(events(:championship), reference_time: Time.zone.parse("2026-04-20 12:00:00")).normal

    assert_equal [ matches(:qm1), matches(:qm2), matches(:qm3), matches(:qm4) ], matches
  end

  test "live returns no matches after the event has ended" do
    matches = ScoutableMatchesQuery.new(events(:championship), reference_time: Time.zone.parse("2026-04-20 12:00:00")).live

    assert_empty matches
  end

  test "replay returns played matches with videos most recent first" do
    matches = ScoutableMatchesQuery.new(events(:championship), reference_time: Time.zone.parse("2026-04-15 11:00:00")).replay

    assert_equal [ matches(:qm4), matches(:qm1) ], matches.select(&:replay_available?)
  end

  test "only qualification matches are scoutable" do
    query = ScoutableMatchesQuery.new(events(:championship), reference_time: Time.zone.parse("2026-04-15 12:30:00"))

    assert_includes query.normal, matches(:qm1)
    assert_not_includes query.live, matches(:sf1)
    assert_not_includes query.live, matches(:f1)
    assert_not_includes query.normal, matches(:sf1)
    assert_not_includes query.normal, matches(:f1)
    assert_not_includes query.replay, matches(:sf1)
    assert_not_includes query.replay, matches(:f1)
  end
end
