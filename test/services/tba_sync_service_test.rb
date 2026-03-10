require "test_helper"

class TbaSyncServiceTest < ActiveSupport::TestCase
  class FakeClient
    def initialize(event_data:, teams_data:, matches_data:)
      @event_data = event_data
      @teams_data = teams_data
      @matches_data = matches_data
    end

    def event(_event_key)
      @event_data
    end

    def event_teams(_event_key)
      @teams_data
    end

    def event_matches(_event_key)
      @matches_data
    end
  end

  test "sync_all! creates qualification placeholders when match feed is empty" do
    event_key = "2026noschedule"
    client = FakeClient.new(
      event_data: {
        "name" => "No Schedule Regional",
        "event_type" => 0,
        "city" => "Nowhere",
        "state_prov" => "TX",
        "country" => "USA",
        "start_date" => "2026-03-01",
        "end_date" => "2026-03-03",
        "year" => 2026,
        "week" => 1
      },
      teams_data: [],
      matches_data: []
    )

    event = TbaSyncService.new(event_key, client: client).sync_all!

    assert_not_nil event
    assert_equal Event::QUALIFICATION_MATCH_COUNT, event.matches.where(comp_level: "qm").count
    assert_equal (
      1..Event::QUALIFICATION_MATCH_COUNT
    ).to_a, event.matches.where(comp_level: "qm").order(:match_number).pluck(:match_number)
  end

  test "sync_all! fills existing placeholder qualification matches from TBA" do
    event = Event.create!(name: "Placeholder Event", tba_key: "2026placeholder", year: 2026)
    event.matches.create!(comp_level: "qm", set_number: 1, match_number: 1)

    client = FakeClient.new(
      event_data: {
        "name" => "Placeholder Event",
        "event_type" => 0,
        "city" => "Houston",
        "state_prov" => "TX",
        "country" => "USA",
        "start_date" => "2026-04-01",
        "end_date" => "2026-04-03",
        "year" => 2026,
        "week" => 4
      },
      teams_data: [],
      matches_data: [
        {
          "key" => "2026placeholder_qm1",
          "comp_level" => "qm",
          "set_number" => nil,
          "match_number" => 1,
          "time" => 1_775_106_000,
          "alliances" => {
            "red" => {
              "score" => 120,
              "team_keys" => [ "frc254" ]
            },
            "blue" => {
              "score" => 110,
              "team_keys" => [ "frc1678" ]
            }
          }
        }
      ]
    )

    synced_event = TbaSyncService.new(event.tba_key, client: client).sync_all!
    synced_match = synced_event.matches.find_by!(comp_level: "qm", match_number: 1)

    assert_equal 1, synced_event.matches.where(comp_level: "qm", match_number: 1).count
    assert_equal "2026placeholder_qm1", synced_match.tba_key
    assert_equal 120, synced_match.red_score
    assert_equal 110, synced_match.blue_score
    assert_equal 2, synced_match.match_alliances.count
  end
end
