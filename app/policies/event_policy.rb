class EventPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def select?
    true
  end

  def create?
    admin_or_lead?
  end

  def update?
    admin_or_lead?
  end

  def destroy?
    admin_or_lead?
  end

  def sync?
    admin_or_lead?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
