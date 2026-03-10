class WebPushSubscriptionPolicy < ApplicationPolicy
  def create?
    scout?
  end

  def unsubscribe?
    scout?
  end
end
