# frozen_string_literal: true

namespace :tba do
  desc "Sync the real match schedule + alliances from TBA (replaces placeholder data)"
  task sync: :environment do
    event_key = ENV.fetch("EVENT_KEY", "2026mibig")
    event = Event.find_by(tba_key: event_key)
    abort "Event '#{event_key}' not found" unless event

    unless TbaClient.configured?
      abort "TBA_API_KEY not set. Add it to .env"
    end

    client = TbaClient.new
    matches_data = client.event_matches(event_key)

    if matches_data.blank? || !matches_data.is_a?(Array) || matches_data.empty?
      puts "No matches on TBA yet for #{event_key}. Try again closer to the event."
      exit
    end

    puts "Found #{matches_data.length} matches on TBA for #{event.name}"
    print "This will REPLACE all existing match alliances. Continue? [y/N] "
    answer = $stdin.gets&.strip&.downcase
    abort "Cancelled." unless answer == "y"

    # Clear existing placeholder alliances
    old_count = MatchAlliance.joins(:match).where(matches: { event_id: event.id }).delete_all
    puts "Removed #{old_count} old match alliances"

    # Re-sync from TBA
    service = TbaSyncService.new(event_key)
    synced = service.sync_matches!
    new_alliances = MatchAlliance.joins(:match).where(matches: { event_id: event.id }).count

    puts "Synced #{synced.compact.count} matches with #{new_alliances} alliances"
    puts "Done!"
  end
end
