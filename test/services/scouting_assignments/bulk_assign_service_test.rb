require "test_helper"

class ScoutingAssignments::BulkAssignServiceTest < ActiveSupport::TestCase
  setup do
    @event = events(:championship)
  end

  test "creates assignments for all users in range" do
    service = ScoutingAssignments::BulkAssignService.new(
      event: @event,
      user_ids: [ users(:lead_user).id, users(:scout_user).id ],
      start_match_number: 1,
      end_match_number: 2,
      notes: "Block"
    )

    assert_difference("ScoutingAssignment.count", 3) do
      service.call
    end
  end

  test "upserts duplicates without creating extra rows" do
    service = ScoutingAssignments::BulkAssignService.new(
      event: @event,
      user_ids: [ users(:admin_user).id ],
      start_match_number: 1,
      end_match_number: 1,
      notes: "Updated note"
    )

    assert_no_difference("ScoutingAssignment.count") do
      service.call
    end

    assert_equal "Updated note", scouting_assignments(:admin_qm1).reload.notes
  end
end
