class ExportsController < ApplicationController
  before_action :require_event!

  def csv
    authorize :export, :csv?

    entries = ScoutingEntry.where(event: current_event).includes(:user, :frc_team, :match)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[ID Match Team Scout Status TotalPoints FuelAccuracy Notes CreatedAt]

      entries.find_each do |entry|
        csv << [
          entry.id,
          entry.match&.display_name,
          entry.frc_team.team_number,
          entry.user.full_name,
          entry.status,
          entry.total_points,
          entry.fuel_accuracy,
          entry.notes,
          entry.created_at.iso8601
        ]
      end
    end

    send_data csv_data,
              filename: "#{current_event.tba_key}_scouting_data_#{Date.current}.csv",
              type: "text/csv"
  end

  def pdf
    authorize :export, :pdf?

    entries = ScoutingEntry.where(event: current_event).includes(:user, :frc_team, :match)
    summaries = TeamEventSummary.where(event: current_event).order(avg_total_points: :desc)

    pdf = Prawn::Document.new(page_size: "LETTER", page_layout: :landscape)

    pdf.text "Scouting Report: #{current_event.name}", size: 18, style: :bold
    pdf.move_down 10
    pdf.text "Generated: #{Time.current.strftime('%B %d, %Y %I:%M %p')}", size: 10
    pdf.move_down 20

    # Team summary table
    if summaries.any?
      pdf.text "Team Summaries", size: 14, style: :bold
      pdf.move_down 10

      table_data = [%w[Team AvgPoints Entries]]
      summaries.each do |summary|
        table_data << [
          summary.frc_team_id,
          summary.avg_total_points&.round(1),
          summary.entries_count
        ]
      end

      pdf.table(table_data, header: true, width: pdf.bounds.width) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = "DDDDDD"
      end
    end

    send_data pdf.render,
              filename: "#{current_event.tba_key}_scouting_report_#{Date.current}.pdf",
              type: "application/pdf"
  end
end
