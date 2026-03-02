class DashboardPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record # will be :dashboard symbol
  end

  def index?
    true
  end
end
