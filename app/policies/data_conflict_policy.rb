class DataConflictPolicy < ApplicationPolicy
  def index?
    analyst? || admin_or_lead?
  end

  def resolve?
    admin_or_lead?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
