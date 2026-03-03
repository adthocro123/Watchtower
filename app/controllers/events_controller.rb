class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy sync]

  def index
    @events = policy_scope(Event).order(start_date: :desc)
  end

  def show
    authorize @event
    @matches = @event.matches.ordered.includes(:frc_teams)
    @teams = FrcTeam.at_event(@event).order(:team_number)
  end

  def new
    @event = Event.new
    authorize @event
  end

  def create
    year = params[:event][:year].to_i
    event_code = params[:event][:event_code].to_s.strip.downcase
    tba_key = "#{year}#{event_code}"

    @event = Event.new(name: params[:event][:name], tba_key: tba_key, year: year)
    authorize @event

    # Fetch details from TBA to auto-populate fields
    tba_data = TbaClient.new.event(tba_key)
    if tba_data
      @event.assign_attributes(
        start_date: tba_data["start_date"],
        end_date: tba_data["end_date"],
        city: tba_data["city"],
        state_prov: tba_data["state_prov"],
        country: tba_data["country"],
        event_type: tba_data["event_type"],
        week: tba_data["week"]
      )
    end

    if @event.save
      redirect_to @event, notice: "Event was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
  end

  def update
    authorize @event

    if @event.update(update_event_params)
      redirect_to @event, notice: "Event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event
    @event.destroy!
    redirect_to events_path, notice: "Event was successfully deleted.", status: :see_other
  end

  # POST /events/:id/select — sets the current event in session
  def select
    @event = Event.find(params[:id])
    authorize @event, :select?

    session[:current_event_id] = @event.id
    redirect_to root_path, notice: "Switched to #{@event.name}."
  end

  # POST /events/:id/sync — triggers TBA sync + Statbotics cache warming + predictions
  def sync
    authorize @event, :sync?

    TbaSyncService.new(@event.tba_key).sync_all!

    # Refresh materialized views, warm Statbotics cache, and regenerate predictions
    RefreshSummariesJob.perform_later(@event.id)
    SyncStatboticsJob.perform_later(@event.id)
    RefreshPredictionsJob.perform_later(@event.id)

    redirect_to @event, notice: "Event data synced from The Blue Alliance. Statbotics data and predictions are updating in the background."
  rescue StandardError => e
    redirect_to @event, alert: "Sync failed: #{e.message}"
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def update_event_params
    params.require(:event).permit(:name, :start_date, :end_date, :city, :state_prov, :country, :event_type)
  end
end
