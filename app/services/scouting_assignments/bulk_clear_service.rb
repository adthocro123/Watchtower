module ScoutingAssignments
  class BulkClearService
    def initialize(event:, user_ids:, start_match_number:, end_match_number:)
      @event = event
      @user_ids = Array(user_ids).map(&:to_i).uniq
      @start_match_number = start_match_number.to_i
      @end_match_number = end_match_number.to_i
    end

    def call
      return 0 if user_ids.empty?

      lower, upper = [ start_match_number, end_match_number ].minmax

      ScoutingAssignment
        .joins(:match)
        .where(event_id: event.id, user_id: user_ids)
        .where(matches: { comp_level: "qm", match_number: lower..upper })
        .delete_all
    end

    private

    attr_reader :event, :user_ids, :start_match_number, :end_match_number
  end
end
