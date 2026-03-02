class ScoutingEntriesController < ApplicationController
  before_action :require_event!, except: :sync
  before_action :set_scouting_entry, only: %i[show edit update destroy]

  def index
    @scouting_entries = policy_scope(ScoutingEntry)
                          .where(event: current_event)
                          .includes(:user, :frc_team, :match)
                          .order(created_at: :desc)
  end

  def show
    authorize @scouting_entry
  end

  def new
    @scouting_entry = ScoutingEntry.new(event: current_event)
    authorize @scouting_entry

    @game_config = GameConfig.current
    @matches = current_event.matches.ordered
    @teams = FrcTeam.at_event(current_event).order(:team_number)
  end

  def create
    @scouting_entry = current_user.scouting_entries.build(scouting_entry_params)
    @scouting_entry.event = current_event
    authorize @scouting_entry

    # Handle offline sync: skip if a duplicate client_uuid already exists
    if @scouting_entry.client_uuid.present?
      existing = ScoutingEntry.find_by(client_uuid: @scouting_entry.client_uuid)
      if existing
        redirect_to existing, notice: "Entry already synced."
        return
      end
    end

    if @scouting_entry.save
      @scouting_entry.broadcast_prepend_to(
        "scouting_entries_event_#{current_event.id}",
        target: "scouting_entries",
        partial: "scouting_entries/scouting_entry",
        locals: { scouting_entry: @scouting_entry }
      )
      redirect_to @scouting_entry, notice: "Scouting entry was successfully created."
    else
      @game_config = GameConfig.current
      @matches = current_event.matches.ordered
      @teams = FrcTeam.at_event(current_event).order(:team_number)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @scouting_entry
    @game_config = GameConfig.current
    @matches = current_event.matches.ordered
    @teams = FrcTeam.at_event(current_event).order(:team_number)
  end

  def update
    authorize @scouting_entry

    if @scouting_entry.update(scouting_entry_params)
      redirect_to @scouting_entry, notice: "Scouting entry was successfully updated."
    else
      @game_config = GameConfig.current
      @matches = current_event.matches.ordered
      @teams = FrcTeam.at_event(current_event).order(:team_number)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @scouting_entry
    @scouting_entry.destroy!
    redirect_to scouting_entries_path, notice: "Scouting entry was successfully deleted.", status: :see_other
  end

  # POST /scouting_entries/sync — offline sync endpoint
  def sync
    authorize :scouting_entry, :sync?

    entries_params = params.require(:entries)
    results = []

    entries_params.each do |entry_data|
      entry = ScoutingEntry.find_by(client_uuid: entry_data[:client_uuid])

      if entry
        results << { client_uuid: entry_data[:client_uuid], status: "existing", id: entry.id }
      else
        entry = ScoutingEntry.from_offline_data(
          entry_data.permit(:match_id, :frc_team_id, :event_id, :notes, :photo_url, :client_uuid, :status, data: {})
                    .merge(user_id: current_user.id)
        )

        if entry.save
          results << { client_uuid: entry_data[:client_uuid], status: "created", id: entry.id }
        else
          results << { client_uuid: entry_data[:client_uuid], status: "error", errors: entry.errors.full_messages }
        end
      end
    end

    render json: { results: results }
  end

  private

  def set_scouting_entry
    @scouting_entry = ScoutingEntry.find(params[:id])
  end

  def scouting_entry_params
    params.require(:scouting_entry).permit(
      :match_id, :frc_team_id, :notes, :photo_url, :client_uuid, :status,
      data: {}
    )
  end
end
