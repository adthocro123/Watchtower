class PickListsController < ApplicationController
  before_action :require_event!
  before_action :set_pick_list, only: %i[show edit update destroy]
  before_action :prepare_show_data, only: :show
  before_action :load_team_options, only: %i[new create edit update]

  def index
    @pick_lists = policy_scope(PickList).where(event: current_event).includes(:user).order(updated_at: :desc)
  end

  def show
    authorize @pick_list
  end

  def new
    @pick_list = current_user.pick_lists.build(event: current_event)
    authorize @pick_list
  end

  def create
    @pick_list = current_user.pick_lists.build(pick_list_params)
    @pick_list.event = current_event
    authorize @pick_list

    if @pick_list.save
      redirect_to @pick_list, notice: "Pick list was successfully created."
    else
      load_team_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @pick_list
  end

  def update
    authorize @pick_list

    if @pick_list.update(pick_list_params)
      respond_to do |format|
        format.html { redirect_to @pick_list, notice: "Pick list was successfully updated." }
        format.json { render json: { id: @pick_list.id, entries: @pick_list.entries }, status: :ok }
      end
    else
      load_team_options
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @pick_list.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @pick_list
    @pick_list.destroy!
    redirect_to pick_lists_path, notice: "Pick list was successfully deleted.", status: :see_other
  end

  private

  def set_pick_list
    @pick_list = PickList.find(params[:id])
  end

  def pick_list_params
    source = params[:pick_list] || params
    permitted = source.permit(:name, entries: [])
    permitted[:entries] ||= []
    permitted
  end

  def prepare_show_data
    @ordered_team_ids = safe_ordered_team_ids(@pick_list)
    @teams_by_id = FrcTeam.where(id: @ordered_team_ids).index_by(&:id)
    @team_summaries = safe_team_summaries(TeamEventSummary.where(event: current_event, frc_team_id: @ordered_team_ids))
  rescue StandardError => e
    Rails.logger.warn("[PickListsController] Failed to prepare pick list #{@pick_list&.id} for display: #{e.class}: #{e.message}")
    @ordered_team_ids = []
    @teams_by_id = {}
    @team_summaries = {}
    @team_summary_warning = true
  end

  def load_team_options
    @pick_list ||= current_user.pick_lists.build(event: current_event)

    summaries = safe_team_summaries(TeamEventSummary.where(event: current_event))
    selected_ids = safe_ordered_team_ids(@pick_list)
    event_rank_by_id = summaries.values.sort_by do |summary|
      [ -summary.avg_total_points.to_f, -summary.matches_scouted.to_i, summary.frc_team_id ]
    end.each_with_index(1).to_h { |summary, index| [ summary.frc_team_id, index ] }

    teams = FrcTeam.at_event(current_event).order(:team_number).to_a
    sorted_teams = teams.sort_by do |team|
      selected_index = selected_ids.index(team.id)

      [
        selected_index.nil? ? 1 : 0,
        selected_index || 9_999,
        selected_index.nil? ? -summaries[team.id]&.avg_total_points.to_f : 0,
        team.team_number
      ]
    end

    @team_options = sorted_teams.map do |team|
      {
        team: team,
        summary: summaries[team.id],
        selected: selected_ids.include?(team.id),
        selected_rank: selected_ids.index(team.id)&.+(1),
        event_rank: event_rank_by_id[team.id]
      }
    end
  rescue StandardError => e
    @team_summary_warning = true
    Rails.logger.warn("[PickListsController] Falling back to basic pick list options for event #{current_event&.id}: #{e.class}: #{e.message}")
    @team_options = fallback_team_options
  end

  def safe_team_summaries(scope)
    scope.index_by(&:frc_team_id)
  rescue StandardError => e
    @team_summary_warning = true
    Rails.logger.warn("[PickListsController] Failed to load team summaries for event #{current_event&.id}: #{e.class}: #{e.message}")
    {}
  end

  def safe_ordered_team_ids(pick_list)
    pick_list.ordered_team_ids
  rescue StandardError => e
    Rails.logger.warn("[PickListsController] Failed to normalize pick list #{pick_list&.id || 'new'} entries: #{e.class}: #{e.message}")
    []
  end

  def fallback_team_options
    selected_ids = safe_ordered_team_ids(@pick_list)

    FrcTeam.at_event(current_event).order(:team_number).map do |team|
      {
        team: team,
        summary: nil,
        selected: selected_ids.include?(team.id),
        selected_rank: selected_ids.index(team.id)&.+(1),
        event_rank: nil
      }
    end
  end
end
