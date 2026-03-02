class PickListsController < ApplicationController
  before_action :require_event!
  before_action :set_pick_list, only: %i[show edit update destroy]

  def index
    @pick_lists = policy_scope(PickList).where(event: current_event).order(updated_at: :desc)
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
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @pick_list
  end

  def update
    authorize @pick_list

    if @pick_list.update(pick_list_params)
      redirect_to @pick_list, notice: "Pick list was successfully updated."
    else
      render :edit, status: :unprocessable_entity
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
    params.require(:pick_list).permit(:name, entries: [])
  end
end
