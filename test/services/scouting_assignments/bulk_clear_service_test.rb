require "test_helper"

class ScoutingAssignments::BulkClearServiceTest < ActiveSupport::TestCase
  setup do
    @event = events(:championship)
  end

  test "clears assignments for selected users in range" do
    service = ScoutingAssignments::BulkClearService.new(
      event: @event,
      user_ids: [ users(:admin_user).id ],
      start_match_number: 1,
      end_match_number: 2
    )

    assert_difference("ScoutingAssignment.count", -2) do
      service.call
    end
  end
end
