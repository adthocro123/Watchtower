class ScoutAccuracyService
  def initialize(event)
    @event = event
  end

  # Returns an array of hashes sorted by accuracy (most accurate first).
  # Scouts with 0 scored matches appear at the bottom sorted by entry count descending.
  #
  # Each hash:
  #   { user:, average_error:, scored_match_count:, total_entry_count: }
  def call
    scored_results = compute_accuracy
    entry_counts = total_entry_counts

    # Build results for scouts with scored matches
    with_accuracy = scored_results.map do |user_id, data|
      {
        user_id: user_id,
        average_error: (data[:total_error].to_f / data[:match_count]).round(1),
        scored_match_count: data[:match_count],
        total_entry_count: entry_counts[user_id] || 0
      }
    end

    # Build results for scouts with entries but no scored matches
    without_accuracy = entry_counts
      .reject { |user_id, _| scored_results.key?(user_id) }
      .map do |user_id, count|
        {
          user_id: user_id,
          average_error: nil,
          scored_match_count: 0,
          total_entry_count: count
        }
      end

    # Sort: scored scouts by average_error ascending, then unscored by entry count descending
    sorted_with = with_accuracy.sort_by { |r| r[:average_error] }
    sorted_without = without_accuracy.sort_by { |r| -r[:total_entry_count] }

    # Load users and attach
    all_user_ids = (sorted_with + sorted_without).map { |r| r[:user_id] }
    users_by_id = User.where(id: all_user_ids).index_by(&:id)

    (sorted_with + sorted_without).map do |result|
      result.merge(user: users_by_id[result[:user_id]])
    end
  end

  private

  # Returns a hash: { user_id => { total_error:, match_count: } }
  def compute_accuracy
    results = {}

    matches_with_scores = @event.matches.with_scores.includes(
      match_alliances: :frc_team,
      scouting_entries: :user
    )

    matches_with_scores.each do |match|
      %w[red blue].each do |color|
        actual_score = color == "red" ? match.red_score : match.blue_score
        next unless actual_score

        # Get the teams on this alliance
        alliance_teams = match.match_alliances.select { |ma| ma.alliance_color == color }
        team_ids = alliance_teams.map(&:frc_team_id)
        next if team_ids.size < 3

        # Find submitted scouting entries for all 3 teams in this match
        entries = match.scouting_entries.select do |e|
          e.submitted? && team_ids.include?(e.frc_team_id)
        end

        # Group by team to get one entry per team (take the first if multiple)
        entries_by_team = entries.group_by(&:frc_team_id)
        next unless team_ids.all? { |tid| entries_by_team.key?(tid) }

        # Sum total_points from the 3 entries (one per team)
        scouted_total = team_ids.sum do |tid|
          entries_by_team[tid].first.total_points
        end

        alliance_error = (scouted_total - actual_score).abs

        # Attribute error to all 3 scouts
        team_ids.each do |tid|
          entry = entries_by_team[tid].first
          user_id = entry.user_id
          results[user_id] ||= { total_error: 0, match_count: 0 }
          results[user_id][:total_error] += alliance_error
          results[user_id][:match_count] += 1
        end
      end
    end

    results
  end

  # Returns { user_id => count } for all submitted entries at this event
  def total_entry_counts
    ScoutingEntry.where(event: @event).submitted.group(:user_id).count
  end
end
