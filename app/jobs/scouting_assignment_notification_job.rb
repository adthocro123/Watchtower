class ScoutingAssignmentNotificationJob < ApplicationJob
  queue_as :default

  THRESHOLDS = [ 5, 2, 1 ].freeze

  def perform(event_id)
    event = Event.find_by(id: event_id)
    return unless event

    ordered_matches = event.matches.where(comp_level: "qm").ordered.to_a
    return if ordered_matches.empty?

    match_index = ordered_matches.each_with_index.to_h
    current_index = latest_completed_match_index(ordered_matches)
    return unless current_index

    assignments = ScoutingAssignment.includes(:match, :user).where(event_id: event.id)

    assignments.find_each do |assignment|
      target_index = match_index[assignment.match]
      next if target_index.nil?

      ahead = target_index - current_index
      next unless THRESHOLDS.include?(ahead)

      notified_column = "notified_#{ahead}_at"
      next if assignment.public_send(notified_column).present?

      delivered = PushNotificationService.new(assignment.user).send_assignment_notification!(
        assignment: assignment,
        matches_ahead: ahead
      )
      next unless delivered

      assignment.update_column(notified_column, Time.current)
    end
  end

  private

  def latest_completed_match_index(ordered_matches)
    latest = ordered_matches.rindex { |match| match.red_score.present? && match.blue_score.present? }
    latest || 0
  end
end
