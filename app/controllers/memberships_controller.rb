class MembershipsController < ApplicationController
  ASSIGNABLE_ROLES = %w[scout analyst lead admin].freeze

  before_action :set_organization
  before_action :set_membership, only: %i[update destroy]

  # PATCH /organizations/:organization_id/memberships/:id
  def update
    authorize @membership

    unless ASSIGNABLE_ROLES.include?(membership_params[:role])
      redirect_to @organization, alert: "Invalid role."
      return
    end

    if @membership.admin? && membership_params[:role] != "admin" && would_remove_last_admin?([@membership.id])
      redirect_to @organization, alert: "Cannot change role — this is the organization's last admin."
      return
    end

    if @membership.update(membership_params)
      redirect_to @organization, notice: "#{@membership.user.full_name}'s role updated to #{@membership.role.capitalize}."
    else
      redirect_to @organization, alert: "Failed to update role."
    end
  end

  # DELETE /organizations/:organization_id/memberships/:id
  def destroy
    authorize @membership

    if @membership.admin? && would_remove_last_admin?([@membership.id])
      redirect_to @organization, alert: "Cannot remove the organization's last admin."
      return
    end

    user_name = @membership.user.full_name
    if @membership.destroy
      redirect_to @organization, notice: "#{user_name} has been removed.", status: :see_other
    else
      redirect_to @organization, alert: "Failed to remove #{user_name}."
    end
  end

  # POST /organizations/:organization_id/memberships/bulk_update
  def bulk_update
    authorize Membership, :bulk_update?

    ids = Array(params[:membership_ids]).map(&:to_i)
    role = params[:role]

    unless ASSIGNABLE_ROLES.include?(role)
      redirect_to @organization, alert: "Invalid role."
      return
    end

    memberships = @organization.memberships.where(id: ids).where.not(role: :owner)

    if role != "admin"
      admin_ids_being_changed = memberships.where(role: :admin).pluck(:id)
      if admin_ids_being_changed.any? && would_remove_last_admin?(admin_ids_being_changed)
        redirect_to @organization, alert: "Cannot change role — this would remove the organization's last admin."
        return
      end
    end

    count = 0
    memberships.each do |m|
      count += 1 if m.update(role: role)
    end

    redirect_to @organization, notice: "Updated #{count} #{"member".pluralize(count)} to #{role.capitalize}."
  end

  # POST /organizations/:organization_id/memberships/bulk_destroy
  def bulk_destroy
    authorize Membership, :bulk_destroy?

    ids = Array(params[:membership_ids]).map(&:to_i)
    memberships = @organization.memberships.where(id: ids).where.not(role: :owner)

    admin_ids_being_removed = memberships.where(role: :admin).pluck(:id)
    if admin_ids_being_removed.any? && would_remove_last_admin?(admin_ids_being_removed)
      redirect_to @organization, alert: "Cannot remove the organization's last admin."
      return
    end

    destroyed = memberships.destroy_all
    count = destroyed.size

    redirect_to @organization, notice: "Removed #{count} #{"member".pluralize(count)}.", status: :see_other
  end

  private

  def set_organization
    @organization = current_user.organizations.find(params[:organization_id])
  end

  def set_membership
    @membership = @organization.memberships.find(params[:id])
  end

  def membership_params
    params.require(:membership).permit(:role)
  end

  # Returns true if excluding the given IDs would leave zero admin-role members
  # (owner is excluded since they can't be demoted/removed anyway).
  def would_remove_last_admin?(excluded_ids)
    @organization.memberships
      .where(role: :admin)
      .where.not(id: excluded_ids)
      .none?
  end
end
