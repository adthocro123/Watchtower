require "test_helper"

class ScoutAccuracyServiceTest < ActiveSupport::TestCase
  setup do
    @event = events(:championship)
    @service = ScoutAccuracyService.new(@event)
  end

  # --- Basic functionality ---

  test "call returns an array of results" do
    results = @service.call
    assert_kind_of Array, results
  end

  test "each result has expected keys" do
    results = @service.call
    results.each do |r|
      assert r.key?(:user_id), "Expected :user_id key"
      assert r.key?(:user), "Expected :user key"
      assert r.key?(:average_error), "Expected :average_error key"
      assert r.key?(:scored_match_count), "Expected :scored_match_count key"
      assert r.key?(:total_entry_count), "Expected :total_entry_count key"
    end
  end

  # --- Accuracy math ---
  #
  # Fixture setup:
  #   qm1 red alliance: 254 (admin_user), 4414 (owner_user), 118 (lead_user)
  #     254 total_points  = 17 fuel + 15 auton_climb + 30 L3 = 62
  #     4414 total_points = 12 fuel + 0 auton_climb  + 20 L2 = 32
  #     118 total_points  = 12 fuel + 15 auton_climb + 10 L1 = 37
  #     scouted_total = 131, actual red_score = 180, error = 49
  #
  #   qm2 red alliance: 1678 (admin_user), 971 (lead_user), 118 (scout_user)
  #     1678 total_points = 15 fuel + 15 auton_climb + 20 L2 = 50
  #     971 total_points  = 15 fuel + 15 auton_climb + 20 L2 = 50
  #     118 total_points  = 9 fuel  + 0 auton_climb  + 10 L1 = 19
  #     scouted_total = 119, actual red_score = 150, error = 31
  #
  #   Blue alliances are incomplete (only 1 team each), so they are skipped.
  #
  # Per scout:
  #   admin_user:  (49 + 31) / 2 = 40.0 avg error, 2 scored matches, 2 total entries
  #   lead_user:   (49 + 31) / 2 = 40.0 avg error, 2 scored matches, 3 total entries
  #   scout_user:  31 / 1 = 31.0 avg error, 1 scored match, 2 total entries
  #   owner_user:  49 / 1 = 49.0 avg error, 1 scored match, 2 total entries

  test "computes correct average error for scouts" do
    results = @service.call
    by_user = results.index_by { |r| r[:user_id] }

    assert_equal 40.0, by_user[users(:admin_user).id][:average_error]
    assert_equal 40.0, by_user[users(:lead_user).id][:average_error]
    assert_equal 31.0, by_user[users(:scout_user).id][:average_error]
    assert_equal 49.0, by_user[users(:owner_user).id][:average_error]
  end

  test "computes correct scored match count" do
    results = @service.call
    by_user = results.index_by { |r| r[:user_id] }

    assert_equal 2, by_user[users(:admin_user).id][:scored_match_count]
    assert_equal 2, by_user[users(:lead_user).id][:scored_match_count]
    assert_equal 1, by_user[users(:scout_user).id][:scored_match_count]
    assert_equal 1, by_user[users(:owner_user).id][:scored_match_count]
  end

  test "computes correct total entry count" do
    results = @service.call
    by_user = results.index_by { |r| r[:user_id] }

    assert_equal 2, by_user[users(:admin_user).id][:total_entry_count]
    assert_equal 2, by_user[users(:scout_user).id][:total_entry_count]
    assert_equal 3, by_user[users(:lead_user).id][:total_entry_count]
    assert_equal 2, by_user[users(:owner_user).id][:total_entry_count]
  end

  # --- Sorting ---

  test "results are sorted by average error ascending" do
    results = @service.call
    errors = results.filter_map { |r| r[:average_error] }

    errors.each_cons(2) do |a, b|
      assert a <= b, "Expected #{a} <= #{b} — scored scouts should be sorted by error ascending"
    end
  end

  test "scout_user is first with lowest error" do
    results = @service.call
    assert_equal users(:scout_user).id, results.first[:user_id]
    assert_equal 31.0, results.first[:average_error]
  end

  test "scouts with accuracy appear before scouts without" do
    # Remove scores from all matches to create scouts without accuracy data
    Match.update_all(red_score: nil, blue_score: nil)

    # Add back score for qm1 only
    matches(:qm1).update!(red_score: 180, blue_score: 120)

    results = @service.call
    scored_indices = results.each_with_index
      .select { |r, _| r[:average_error].present? }
      .map(&:last)
    unscored_indices = results.each_with_index
      .select { |r, _| r[:average_error].nil? }
      .map(&:last)

    if scored_indices.any? && unscored_indices.any?
      assert scored_indices.max < unscored_indices.min,
        "All scored scouts should appear before unscored scouts"
    end
  end

  # --- Edge cases ---

  test "returns empty array for event with no entries" do
    empty_event = Event.create!(
      name: "Empty Event",
      tba_key: "2026empty",
      start_date: "2026-05-01",
      end_date: "2026-05-03",
      year: 2026
    )
    results = ScoutAccuracyService.new(empty_event).call
    assert_equal [], results
  end

  test "skips matches without scores" do
    # Remove scores from qm2 to make it unscored
    match = matches(:qm2)
    match.update!(red_score: nil, blue_score: nil)

    results = @service.call
    scored = results.select { |r| r[:scored_match_count] > 0 }

    # Only qm1 red contributes now — error = 49 for 3 scouts (admin, owner, lead)
    assert_equal 3, scored.size
    scored.each do |r|
      assert_equal 1, r[:scored_match_count]
      assert_equal 49.0, r[:average_error]
    end
  end

  test "skips alliances with fewer than 3 scouting entries" do
    # The blue alliances in fixtures only have 1 team each,
    # so they should already be skipped. Total scored alliances = 2 (both red).
    results = @service.call
    total_scored = results.sum { |r| r[:scored_match_count] }

    # 2 alliances * 3 scouts each = 6 total scored-match attributions
    assert_equal 6, total_scored
  end

  test "unscored scouts appear at bottom with nil accuracy" do
    # Remove all match scores so no one has accuracy
    Match.update_all(red_score: nil, blue_score: nil)

    # Re-add score for qm1 only
    matches(:qm1).update!(red_score: 180, blue_score: 120)

    results = @service.call
    # scout_user has entries only for qm2, so should have no scored matches
    scout_result = results.find { |r| r[:user_id] == users(:scout_user).id }

    assert_not_nil scout_result
    assert_nil scout_result[:average_error]
    assert_equal 0, scout_result[:scored_match_count]
  end

  test "approved entries still count toward scout accuracy" do
    scouting_entries(:entry_qm2_254).update!(status: :approved)
    scouting_entries(:entry_qm2_118).update!(status: :approved)

    results = @service.call
    scout_result = results.find { |r| r[:user_id] == users(:scout_user).id }

    assert_not_nil scout_result
    assert_equal 2, scout_result[:total_entry_count]
    assert_equal 1, scout_result[:scored_match_count]
  end
end
