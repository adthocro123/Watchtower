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
    @event = Event.new(event_params)
    authorize @event

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

    if @event.update(event_params)
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

  # POST /events/:id/sync — triggers TBA sync
  def sync
    authorize @event, :sync?

    TbaSyncService.new(@event.tba_key).sync_all!
    redirect_to @event, notice: "Event data synced from The Blue Alliance."
  rescue StandardError => e
    redirect_to @event, alert: "Sync failed: #{e.message}"
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:name, :tba_key, :year, :start_date, :end_date, :location, :event_type)
  end
end
