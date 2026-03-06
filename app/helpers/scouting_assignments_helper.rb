module ScoutingAssignmentsHelper
  def timeline_coverage_classes(count)
    return "bg-red-500/10 border-red-500/30" if count < 3
    return "bg-amber-500/10 border-amber-500/30" if count > 3

    "bg-emerald-500/10 border-emerald-500/30"
  end

  def assignment_notification_badge(assignment)
    return "-- -- --" unless assignment

    [
      assignment.notified_5_at.present? ? "5" : "-",
      assignment.notified_2_at.present? ? "2" : "-",
      assignment.notified_1_at.present? ? "1" : "-"
    ].join(" ")
  end
end
