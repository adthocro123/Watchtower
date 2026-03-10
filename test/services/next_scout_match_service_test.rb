require "test_helper"

class NextScoutMatchServiceTest < ActiveSupport::TestCase
  test "next_match picks next future match with open coverage" do
    service = NextScoutMatchService.new(events(:championship), reference_time: Time.zone.parse("2026-04-15 10:30:00"))

    assert_equal matches(:qm2), service.next_match
  end

  test "next_match can skip current match" do
    service = NextScoutMatchService.new(events(:championship), reference_time: Time.zone.parse("2026-04-15 10:30:00"))

    assert_equal matches(:qm3), service.next_match(after_match: matches(:qm2))
  end

  test "next_match does not treat flagged entries as coverage" do
    scouting_entries(:entry_qm2_254).update!(status: :flagged)
    scouting_entries(:entry_qm2_1678).update!(status: :flagged)
    scouting_entries(:entry_qm2_971).update!(status: :flagged)
    scouting_entries(:entry_qm2_118).update!(status: :flagged)

    service = NextScoutMatchService.new(events(:championship), reference_time: Time.zone.parse("2026-04-15 10:30:00"))

    assert_equal matches(:qm2), service.next_match
  end
end
