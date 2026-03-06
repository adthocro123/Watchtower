require "test_helper"

class PushNotificationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin_user)
    @assignment = scouting_assignments(:admin_qm2)
  end

  test "sends payload to each subscription" do
    ENV["VAPID_PUBLIC_KEY"] = "public"
    ENV["VAPID_PRIVATE_KEY"] = "private"

    captured = []
    with_stubbed_webpush(captured) do
      PushNotificationService.new(@user).send_assignment_notification!(assignment: @assignment, matches_ahead: 2)
    end

    assert_equal 1, captured.length
    assert_equal web_push_subscriptions(:admin_phone).endpoint, captured.first[:endpoint]
  ensure
    ENV.delete("VAPID_PUBLIC_KEY")
    ENV.delete("VAPID_PRIVATE_KEY")
  end

  test "returns false when delivery fails" do
    ENV["VAPID_PUBLIC_KEY"] = "public"
    ENV["VAPID_PRIVATE_KEY"] = "private"

    with_stubbed_webpush_error do
      delivered = PushNotificationService.new(@user).send_assignment_notification!(
        assignment: @assignment,
        matches_ahead: 2
      )

      assert_not delivered
    end
  ensure
    ENV.delete("VAPID_PUBLIC_KEY")
    ENV.delete("VAPID_PRIVATE_KEY")
  end

  test "send_test_notification succeeds with subscription" do
    ENV["VAPID_PUBLIC_KEY"] = "public"
    ENV["VAPID_PRIVATE_KEY"] = "private"

    with_stubbed_webpush([]) do
      delivered = PushNotificationService.new(@user).send_test_notification!
      assert delivered
    end
  ensure
    ENV.delete("VAPID_PUBLIC_KEY")
    ENV.delete("VAPID_PRIVATE_KEY")
  end

  private

  def with_stubbed_webpush(captured)
    singleton = class << Webpush; self; end
    singleton.send(:alias_method, :__original_payload_send_for_test, :payload_send)
    singleton.send(:define_method, :payload_send) do |**kwargs|
      captured << kwargs
      true
    end

    yield
  ensure
    singleton.send(:alias_method, :payload_send, :__original_payload_send_for_test)
    singleton.send(:remove_method, :__original_payload_send_for_test)
  end

  def with_stubbed_webpush_error
    singleton = class << Webpush; self; end
    singleton.send(:alias_method, :__original_payload_send_for_test, :payload_send)
    singleton.send(:define_method, :payload_send) do |**_kwargs|
      raise StandardError, "simulated failure"
    end

    yield
  ensure
    singleton.send(:alias_method, :payload_send, :__original_payload_send_for_test)
    singleton.send(:remove_method, :__original_payload_send_for_test)
  end
end
