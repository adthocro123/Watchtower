class CreateTeamEventSummariesMaterializedView < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW team_event_summaries AS
      SELECT
        se.event_id,
        se.frc_team_id,
        COUNT(*) AS matches_scouted,
        AVG(COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
            COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
            COALESCE((se.data->>'endgame_fuel_made')::numeric, 0)) AS avg_fuel_made,
        AVG(COALESCE((se.data->>'auton_fuel_missed')::numeric, 0) +
            COALESCE((se.data->>'teleop_fuel_missed')::numeric, 0) +
            COALESCE((se.data->>'endgame_fuel_missed')::numeric, 0)) AS avg_fuel_missed,
        CASE
          WHEN SUM(COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
                   COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
                   COALESCE((se.data->>'endgame_fuel_made')::numeric, 0) +
                   COALESCE((se.data->>'auton_fuel_missed')::numeric, 0) +
                   COALESCE((se.data->>'teleop_fuel_missed')::numeric, 0) +
                   COALESCE((se.data->>'endgame_fuel_missed')::numeric, 0)) > 0
          THEN
            ROUND(
              SUM(COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
                  COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
                  COALESCE((se.data->>'endgame_fuel_made')::numeric, 0)) * 100.0 /
              NULLIF(SUM(COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
                         COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
                         COALESCE((se.data->>'endgame_fuel_made')::numeric, 0) +
                         COALESCE((se.data->>'auton_fuel_missed')::numeric, 0) +
                         COALESCE((se.data->>'teleop_fuel_missed')::numeric, 0) +
                         COALESCE((se.data->>'endgame_fuel_missed')::numeric, 0)), 0),
              1)
          ELSE 0
        END AS fuel_accuracy_pct,
        AVG(CASE
          WHEN se.data->>'endgame_climb' = 'L3' THEN 30
          WHEN se.data->>'endgame_climb' = 'L2' THEN 20
          WHEN se.data->>'endgame_climb' = 'L1' THEN 10
          ELSE 0
        END) AS avg_climb_points,
        AVG(
          COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((se.data->>'endgame_fuel_made')::numeric, 0) +
          CASE WHEN (se.data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE
            WHEN se.data->>'endgame_climb' = 'L3' THEN 30
            WHEN se.data->>'endgame_climb' = 'L2' THEN 20
            WHEN se.data->>'endgame_climb' = 'L1' THEN 10
            ELSE 0
          END
        ) AS avg_total_points,
        STDDEV_SAMP(
          COALESCE((se.data->>'auton_fuel_made')::numeric, 0) +
          COALESCE((se.data->>'teleop_fuel_made')::numeric, 0) +
          COALESCE((se.data->>'endgame_fuel_made')::numeric, 0) +
          CASE WHEN (se.data->>'auton_climb')::boolean THEN 15 ELSE 0 END +
          CASE
            WHEN se.data->>'endgame_climb' = 'L3' THEN 30
            WHEN se.data->>'endgame_climb' = 'L2' THEN 20
            WHEN se.data->>'endgame_climb' = 'L1' THEN 10
            ELSE 0
          END
        ) AS stddev_total_points,
        MAX(se.updated_at) AS last_updated
      FROM scouting_entries se
      WHERE se.status = 0
      GROUP BY se.event_id, se.frc_team_id
      WITH DATA;

      CREATE UNIQUE INDEX idx_team_event_summaries ON team_event_summaries (event_id, frc_team_id);
    SQL
  end

  def down
    execute "DROP MATERIALIZED VIEW IF EXISTS team_event_summaries;"
  end
end
