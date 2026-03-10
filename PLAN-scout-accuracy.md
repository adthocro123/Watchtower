# Scout Accuracy Leaderboard — Implementation Plan

Replace the current entry-count leaderboard with one ranked by **alliance accuracy**: how close the sum of 3 scouts' reported points matches the actual alliance score from TBA.

## How It Works

For each completed match where TBA has actual scores:

1. Look up all scouting entries for the 3 teams on each alliance in that match
2. Sum `total_points` from each scout's entry -> **scouted alliance score**
3. Get the **actual alliance score** from TBA
4. Compute error: `|scouted_total - actual_score|`
5. Attribute that error to all 3 scouts for that match

Per scout: compute **average error** across all their scored matches. Lower = better. Display entry count as a secondary stat. No minimum match threshold — show accuracy for any scout with at least 1 scored match. Scouts with 0 scored matches appear at the bottom sorted by entry count.

## Files to Change

### New: Migration — Add scores to matches

Add `red_score` (integer, nullable) and `blue_score` (integer, nullable) to the `matches` table. Null means the match hasn't been played yet.

### `app/models/match.rb`

Add scope: `scope :with_scores, -> { where.not(red_score: nil, blue_score: nil) }`

### `app/services/tba_sync_service.rb`

Update `sync_single_match` to extract `alliances["red"]["score"]` and `alliances["blue"]["score"]` from the TBA match response and persist them. These fields are already returned by the API — the sync currently ignores them.

### New: `app/services/scout_accuracy_service.rb`

**Input:** An event.

**Logic:**
1. Find all matches for the event that have actual scores
2. For each match, for each alliance (red, blue):
   - Get the 3 teams via `match_alliances` where `alliance_color` matches
   - Find scouting entries (status: submitted) for all 3 teams in this match
   - If all 3 exist: sum `total_points` -> scouted total, compute `|scouted_total - actual_score|` -> alliance error, attribute to all 3 scouts
3. Per scout: compute `average_error` across all attributed matches, plus `scored_match_count`
4. Also compute `total_entry_count` per scout (all entries at this event)
5. Return results sorted by `average_error` ascending (most accurate first); scouts with 0 scored matches go at the bottom sorted by entry count descending

### `app/controllers/dashboard_controller.rb`

Replace the current `@scout_activity` / `@top_scouts` logic with a call to `ScoutAccuracyService.new(@event).call`.

### `app/views/dashboard/index.html.erb`

Rework the leaderboard section:
- Ranked by accuracy (lowest avg error first)
- Each row: scout name, avg points off (e.g., "~3.2 pts off"), entry count
- Scouts with no scored matches: show at bottom with entry count and "No data" for accuracy
- Progress bar width based on accuracy (inverted — most accurate gets widest bar)

### Tests

- `test/services/scout_accuracy_service_test.rb` — test accuracy math with fixtures (matches with known scores, entries with known totals)
- `test/controllers/dashboard_controller_test.rb` — update for new leaderboard data
- Add `red_score`/`blue_score` values to match fixtures
