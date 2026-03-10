# frozen_string_literal: true

class TbaSyncService
  def initialize(event_key, client: TbaClient.new)
    @event_key = event_key
    @client = client
  end

  # Runs all syncs in order: event, teams, matches.
  def sync_all!
    event = sync_event!
    return nil unless event

    sync_teams!
    sync_matches!
    event.ensure_qualification_matches!
    event
  end

  # Creates or updates the Event record from TBA data.
  def sync_event!
    data = @client.event(@event_key)
    return nil unless data

    Event.find_or_initialize_by(tba_key: @event_key).tap do |event|
      event.assign_attributes(
        name: data["name"],
        event_type: data["event_type"],
        city: data["city"],
        state_prov: data["state_prov"],
        country: data["country"],
        start_date: data["start_date"],
        end_date: data["end_date"],
        year: data["year"],
        week: data["week"]
      )
      event.save!
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[TbaSyncService] Failed to sync event #{@event_key}: #{e.message}")
    nil
  end

  # Creates or updates FrcTeam records for all teams at the event.
  def sync_teams!
    teams_data = @client.event_teams(@event_key)
    return [] unless teams_data.is_a?(Array)

    event = Event.find_by(tba_key: @event_key)

    teams_data.filter_map do |data|
      team_number = data["team_number"]
      next unless team_number

      team = FrcTeam.find_or_initialize_by(team_number: team_number)
      team.assign_attributes(
        nickname: data["nickname"],
        city: data["city"],
        state_prov: data["state_prov"],
        country: data["country"],
        rookie_year: data["rookie_year"],
        website: data["website"]
      )
      team.save!

      # Link team to event
      EventTeam.find_or_create_by!(event: event, frc_team: team) if event

      team
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[TbaSyncService] Failed to sync team #{team_number}: #{e.message}")
      nil
    end
  end

  # Creates or updates Match and MatchAlliance records for the event.
  def sync_matches!
    matches_data = @client.event_matches(@event_key)
    return [] unless matches_data.is_a?(Array)

    event = Event.find_by(tba_key: @event_key)
    return [] unless event

    matches_data.filter_map do |data|
      sync_single_match(event, data)
    end
  end

  private

  def sync_single_match(event, data)
    set_number = normalized_set_number(data)
    match = Match.find_by(tba_key: data["key"]) ||
            event.matches.find_by(
              comp_level: data["comp_level"],
              set_number: set_number,
              match_number: data["match_number"],
              tba_key: nil
            ) ||
            Match.new

    match.assign_attributes(
      tba_key: data["key"],
      event: event,
      comp_level: data["comp_level"],
      set_number: set_number,
      match_number: data["match_number"],
      scheduled_time: parse_time(data["time"]),
      actual_time: parse_time(data["actual_time"]),
      predicted_time: parse_time(data["predicted_time"]),
      post_result_time: parse_time(data["post_result_time"]),
      videos: Array(data["videos"]),
      red_score: data.dig("alliances", "red", "score"),
      blue_score: data.dig("alliances", "blue", "score")
    )
    match.save!

    sync_alliances(match, data["alliances"]) if data["alliances"]

    match
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[TbaSyncService] Failed to sync match #{data['key']}: #{e.message}")
    nil
  end

  def sync_alliances(match, alliances)
    %w[red blue].each do |color|
      alliance_data = alliances.dig(color, "team_keys") || []

      alliance_data.each_with_index do |team_key, index|
        # TBA team keys are formatted as "frcNNNN"
        team_number = team_key.delete_prefix("frc").to_i
        frc_team = FrcTeam.find_by(team_number: team_number)
        next unless frc_team

        ma = MatchAlliance.find_or_initialize_by(match: match, frc_team: frc_team)
        ma.assign_attributes(
          alliance_color: color,
          station: index + 1
        )
        ma.save!
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error(
          "[TbaSyncService] Failed to sync alliance for match #{match.tba_key}, " \
          "team #{team_number}: #{e.message}"
        )
      end
    end
  end

  def parse_time(epoch)
    return nil unless epoch
    Time.at(epoch).utc
  end

  def normalized_set_number(data)
    return 1 if data["comp_level"] == "qm" && data["set_number"].blank?

    data["set_number"]
  end
end
