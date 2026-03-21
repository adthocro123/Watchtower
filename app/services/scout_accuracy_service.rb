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
  #
  # Uses every counted entry on scored matches, including partially scouted
  # alliances. Each entry is compared against an equal-share expected score for
  # that alliance (actual alliance score divided by alliance team count).
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
        next if team_ids.empty?

        expected_points_per_team = actual_score.to_f / team_ids.size

        # Find counted scouting entries for teams on this alliance
        entries = match.scouting_entries.select do |e|
          e.counted? && team_ids.include?(e.frc_team_id)
        end

        # Score each counted entry independently so partial alliances count.
        entries.each do |entry|
          user_id = entry.user_id
          entry_error = (entry.total_points - expected_points_per_team).abs

          results[user_id] ||= { total_error: 0, match_count: 0 }
          results[user_id][:total_error] += entry_error
          results[user_id][:match_count] += 1
        end
      end
    end

    results
  end

  # Returns { user_id => count } for all counted entries at this event
  def total_entry_counts
    ScoutingEntry.where(event: @event).counted.group(:user_id).count
  end
end
