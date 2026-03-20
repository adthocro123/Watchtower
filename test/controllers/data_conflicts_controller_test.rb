require "test_helper"

class DataConflictsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    @conflict = data_conflicts(:conflict_qm1_254_climb)
    @secondary_entry = ScoutingEntry.create!(
      user: users(:lead_user),
      match: matches(:qm1),
      frc_team: frc_teams(:team_254),
      event: @event,
      data: {
        "auton_fuel_made" => 5,
        "teleop_fuel_made" => 12,
        "endgame_climb" => "L2"
      },
      status: :flagged,
      client_uuid: "conflict-secondary-#{SecureRandom.hex(8)}"
    )
    sign_in_as(@user)
    select_event(@event)
  end

  test "admin can resolve a conflict" do
    post resolve_data_conflict_path(@conflict), params: { resolution: "L3" }

    assert_redirected_to data_conflicts_path

    @conflict.reload
    assert @conflict.resolved
    assert_equal @user, @conflict.resolved_by
    assert_equal "L3", @conflict.resolution_value

    assert_equal "L3", scouting_entries(:entry_qm1_254).reload.data["endgame_climb"]
    assert_equal "L3", @secondary_entry.reload.data["endgame_climb"]
  end

  test "admin can resolve a conflict and approve a scout entry" do
    post resolve_data_conflict_path(@conflict), params: { resolution: "L3", approved_entry_id: @secondary_entry.id }

    assert_redirected_to data_conflicts_path
    assert @secondary_entry.reload.approved?
  end

  test "resolve rejects approval for non-flagged entries" do
    post resolve_data_conflict_path(@conflict), params: { resolution: "L3", approved_entry_id: scouting_entries(:entry_qm1_254).id }

    assert_redirected_to data_conflicts_path
    assert_equal "L2", @secondary_entry.reload.data["endgame_climb"]
    assert scouting_entries(:entry_qm1_254).submitted?
    assert_not @conflict.reload.resolved?
  end

  test "scout cannot resolve a conflict" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    post resolve_data_conflict_path(@conflict), params: { resolution: "L3" }

    assert_response :redirect

    @conflict.reload
    assert_not @conflict.resolved
    assert_nil @conflict.resolved_by
    assert_nil @conflict.resolution_value
  end
end
