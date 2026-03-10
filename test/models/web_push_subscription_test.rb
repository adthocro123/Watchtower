require "test_helper"

class WebPushSubscriptionTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert web_push_subscriptions(:admin_phone).valid?
  end

  test "requires unique endpoint" do
    duplicate = WebPushSubscription.new(
      user: users(:lead_user),
      endpoint: web_push_subscriptions(:admin_phone).endpoint,
      p256dh: "another-key",
      auth: "another-auth"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:endpoint], "has already been taken"
  end
end
