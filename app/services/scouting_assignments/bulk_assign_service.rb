module ScoutingAssignments
  class BulkAssignService
    def initialize(event:, user_ids:, start_match_number:, end_match_number:, notes: nil)
      @event = event
      @user_ids = Array(user_ids).map(&:to_i).uniq
      @start_match_number = start_match_number.to_i
      @end_match_number = end_match_number.to_i
      @notes = notes
    end

    def call
      return 0 if user_ids.empty?

      match_ids = qualifying_match_ids
      return 0 if match_ids.empty?

      now = Time.current
      rows = user_ids.product(match_ids).map do |user_id, match_id|
        {
          event_id: event.id,
          user_id: user_id,
          match_id: match_id,
          notes: notes,
          created_at: now,
          updated_at: now
        }
      end

      ScoutingAssignment.upsert_all(rows, unique_by: :idx_scouting_assignments_unique)
      rows.length
    end

    private

    attr_reader :event, :user_ids, :start_match_number, :end_match_number, :notes

    def qualifying_match_ids
      lower, upper = [ start_match_number, end_match_number ].minmax

      event.matches
           .where(comp_level: "qm")
           .where(match_number: lower..upper)
           .ordered
           .pluck(:id)
    end
  end
end
