require "test_helper"

class ScoutingAssignmentTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert scouting_assignments(:admin_qm1).valid?
  end

  test "requires unique event user match" do
    duplicate = ScoutingAssignment.new(
      event: events(:championship),
      user: users(:admin_user),
      match: matches(:qm1)
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:event_id], "has already been taken"
  end

  test "match must belong to event" do
    other_event = Event.create!(
      name: "Other Event",
      tba_key: "2026oth",
      event_type: 0,
      year: 2026
    )

    assignment = ScoutingAssignment.new(
      event: other_event,
      user: users(:admin_user),
      match: matches(:qm1)
    )

    assert_not assignment.valid?
    assert_includes assignment.errors[:match_id], "must belong to the selected event"
  end
end
