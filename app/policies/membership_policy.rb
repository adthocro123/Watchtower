class MembershipPolicy < ApplicationPolicy
  # Admin+ can update roles, but not the owner's membership
  def update?
    admin? && !target_is_owner?
  end

  # Admin+ can remove members, but not the owner
  def destroy?
    admin? && !target_is_owner?
  end

  # Admin+ can perform bulk operations
  def bulk_update?
    admin?
  end

  def bulk_destroy?
    admin?
  end

  private

  # The owner (organization creator) cannot be modified or removed
  def target_is_owner?
    record.owner?
  end
end
