require "test_helper"

class MatchTest < ActiveSupport::TestCase
  # --- Associations ---

  test "belongs to event" do
    match = matches(:qm1)
    assert_equal events(:championship), match.event
  end

  test "has many match_alliances" do
    match = matches(:qm1)
    assert_respond_to match, :match_alliances
    assert_includes match.match_alliances, match_alliances(:qm1_red_1)
    assert_includes match.match_alliances, match_alliances(:qm1_blue_1)
  end

  test "has many frc_teams through match_alliances" do
    match = matches(:qm1)
    assert_respond_to match, :frc_teams
    assert_includes match.frc_teams, frc_teams(:team_254)
    assert_includes match.frc_teams, frc_teams(:team_1678)
  end

  test "has many scouting_entries" do
    match = matches(:qm1)
    assert_respond_to match, :scouting_entries
    assert_includes match.scouting_entries, scouting_entries(:entry_qm1_254)
    assert_includes match.scouting_entries, scouting_entries(:entry_qm1_1678)
  end

  # --- Scopes ---

  test "ordered scope orders by comp_level and match_number" do
    ordered = Match.ordered
    qm1_idx = ordered.index(matches(:qm1))
    qm2_idx = ordered.index(matches(:qm2))
    assert qm1_idx < qm2_idx, "qm1 should come before qm2"
  end

  test "COMP_LEVEL_ORDER constant" do
    expected = { "qm" => 0, "ef" => 1, "qf" => 2, "sf" => 3, "f" => 4 }
    assert_equal expected, Match::COMP_LEVEL_ORDER
  end

  # --- Instance Methods ---

  test "display_name for qualification match" do
    assert_equal "Q1", matches(:qm1).display_name
    assert_equal "Q2", matches(:qm2).display_name
  end

  test "display_name for quarterfinal match" do
    match = Match.new(comp_level: "qf", set_number: 2, match_number: 1)
    assert_equal "QF2-1", match.display_name
  end

  test "display_name for semifinal match" do
    match = Match.new(comp_level: "sf", set_number: 1, match_number: 2)
    assert_equal "SF1-2", match.display_name
  end

  test "display_name for final match" do
    match = Match.new(comp_level: "f", match_number: 3)
    assert_equal "F3", match.display_name
  end

  test "display_name for eighthfinal match" do
    match = Match.new(comp_level: "ef", set_number: 1, match_number: 2)
    assert_equal "EF1-2", match.display_name
  end

  test "display_name for unknown comp_level" do
    match = Match.new(comp_level: "abc", match_number: 1)
    assert_equal "ABC1", match.display_name
  end

  test "best_known_time prefers actual then predicted then scheduled" do
    match = matches(:qm1)
    assert_equal match.actual_time, match.best_known_time

    match.actual_time = nil
    assert_equal match.predicted_time, match.best_known_time

    match.predicted_time = nil
    assert_equal match.scheduled_time, match.best_known_time
  end

  test "occurred true when post_result_time exists" do
    assert matches(:qm1).occurred?(Time.zone.parse("2026-04-15 10:04:00"))
  end

  test "upcoming true when predicted time is in future" do
    assert matches(:qm2).upcoming?(Time.zone.parse("2026-04-15 10:04:00"))
  end

  test "occurred falls back to scheduled time when no actual or result time" do
    assert matches(:qm2).occurred?(Time.zone.parse("2099-04-15 10:20:00"))
  end

  test "youtube_videos parses raw keys and timestamps" do
    videos = matches(:qm1).youtube_videos

    assert_equal 2, videos.length
    assert_equal "pastmatchone", videos.first["video_id"]
    assert_equal 15, videos.first["start_seconds"]
  end

  test "default_replay_video returns first youtube video" do
    assert_equal "pastmatchone?t=15", matches(:qm1).default_replay_video["raw_key"]
  end

  test "video urls include start offsets" do
    match = matches(:qm1)
    video = match.default_replay_video

    assert_equal "https://www.youtube.com/embed/pastmatchone?start=15", match.video_embed_url(video)
    assert_equal "https://www.youtube.com/watch?v=pastmatchone&t=15s", match.video_watch_url(video)
  end

  # --- Dependent destroy ---

  test "destroying match destroys dependent match_alliances" do
    event = Event.create!(name: "Temp Event", tba_key: "2026temp", year: 2026)
    match = Match.create!(event: event, comp_level: "qm", match_number: 99, set_number: 1)
    alliance = MatchAlliance.create!(match: match, frc_team: frc_teams(:team_118), alliance_color: "red", station: 1)
    alliance_id = alliance.id
    match.destroy
    assert_nil MatchAlliance.find_by(id: alliance_id)
  end

  test "destroying match destroys dependent scouting_entries" do
    event = Event.create!(name: "Temp Event 2", tba_key: "2026temp2", year: 2026)
    match = Match.create!(event: event, comp_level: "qm", match_number: 99, set_number: 1)
    entry = ScoutingEntry.create!(
      match: match, user: users(:admin_user),
      frc_team: frc_teams(:team_254), event: event, data: {}
    )
    entry_id = entry.id
    match.destroy
    assert_nil ScoutingEntry.find_by(id: entry_id)
  end
end
