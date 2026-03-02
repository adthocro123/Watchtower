class MatchSimulatorPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record # will be :match_simulator symbol
  end

  def new?
    analyst? || admin_or_lead?
  end

  def create?
    analyst? || admin_or_lead?
  end
end
