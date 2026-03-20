class IncludeApprovedEntriesInTeamEventSummaries < ActiveRecord::Migration[8.1]
  def up
    rebuild_view!("status IN (0, 3)")
  end

  def down
    rebuild_view!("status = 0")
  end

  private

  def rebuild_view!(status_sql)
    execute "DROP MATERIALIZED VIEW IF EXISTS team_event_summaries"

    execute <<~SQL
      CREATE MATERIALIZED VIEW team_event_summaries AS
      SELECT
        event_id,
        frc_team_id,
        COUNT(*) AS matches_scouted,
        AVG(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_made')::numeric, 0)
        ) AS avg_fuel_made,
        AVG(
          COALESCE((data->>'auton_fuel_missed')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_missed')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_missed')::numeric, 0)
        ) AS avg_fuel_missed,
        CASE
          WHEN SUM(
            COALESCE((data->>'auton_fuel_made')::numeric, 0) +
            COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
            COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
            COALESCE((data->>'auton_fuel_missed')::numeric, 0) +
            COALESCE((data->>'teleop_fuel_missed')::numeric, 0) +
            COALESCE((data->>'endgame_fuel_missed')::numeric, 0)
          ) > 0
          THEN ROUND(
            SUM(
              COALESCE((data->>'auton_fuel_made')::numeric, 0) +
              COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
              COALESCE((data->>'endgame_fuel_made')::numeric, 0)
            ) * 100.0 /
            NULLIF(SUM(
              COALESCE((data->>'auton_fuel_made')::numeric, 0) +
              COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
              COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
              COALESCE((data->>'auton_fuel_missed')::numeric, 0) +
              COALESCE((data->>'teleop_fuel_missed')::numeric, 0) +
              COALESCE((data->>'endgame_fuel_missed')::numeric, 0)
            ), 0), 1)
          ELSE 0
        END AS fuel_accuracy_pct,
        AVG(
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE data->>'endgame_climb'
            WHEN 'L3' THEN 30
            WHEN 'L2' THEN 20
            WHEN 'L1' THEN 10
            ELSE 0
          END
        ) AS avg_climb_points,
        AVG(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE data->>'endgame_climb'
            WHEN 'L3' THEN 30
            WHEN 'L2' THEN 20
            WHEN 'L1' THEN 10
            ELSE 0
          END
        ) AS avg_total_points,
        STDDEV_SAMP(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((data->>'endgame_fuel_made')::numeric, 0) +
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE data->>'endgame_climb'
            WHEN 'L3' THEN 30
            WHEN 'L2' THEN 20
            WHEN 'L1' THEN 10
            ELSE 0
          END
        ) AS stddev_total_points,
        AVG(
          COALESCE((data->>'auton_fuel_made')::numeric, 0) +
          CASE WHEN (data->>'auton_climb')::boolean THEN 15 ELSE 0 END
        ) AS avg_auton_points,
        AVG(NULLIF(COALESCE((data->>'defense_rating')::numeric, 0), 0)) AS avg_defense_rating,
        MAX(updated_at) AS last_updated
      FROM scouting_entries
      WHERE #{status_sql}
      GROUP BY event_id, frc_team_id
      WITH NO DATA
    SQL

    add_index :team_event_summaries, [ :event_id, :frc_team_id ],
              unique: true, name: "idx_team_event_summaries"

    execute "REFRESH MATERIALIZED VIEW team_event_summaries"
  end
end
