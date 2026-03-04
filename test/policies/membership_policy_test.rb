require "test_helper"

class MembershipPolicyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:team_254)
    Current.organization = @organization

    @owner_user = users(:owner_user)
    @admin_user = users(:admin_user)
    @lead_user = users(:lead_user)
    @scout_user = users(:scout_user)

    @owner_membership = memberships(:owner_membership)
    @admin_membership = memberships(:admin_membership)
    @lead_membership = memberships(:lead_membership)
    @scout_membership = memberships(:scout_membership)
  end

  # --- update? ---

  test "admin can update a non-owner membership" do
    policy = MembershipPolicy.new(@admin_user, @scout_membership)
    assert policy.update?
  end

  test "admin can update a lead membership" do
    policy = MembershipPolicy.new(@admin_user, @lead_membership)
    assert policy.update?
  end

  test "admin cannot update owner membership" do
    policy = MembershipPolicy.new(@admin_user, @owner_membership)
    assert_not policy.update?
  end

  test "lead cannot update any membership" do
    policy = MembershipPolicy.new(@lead_user, @scout_membership)
    assert_not policy.update?
  end

  test "scout cannot update any membership" do
    policy = MembershipPolicy.new(@scout_user, @scout_membership)
    assert_not policy.update?
  end

  # --- destroy? ---

  test "admin can destroy a non-owner membership" do
    policy = MembershipPolicy.new(@admin_user, @scout_membership)
    assert policy.destroy?
  end

  test "admin cannot destroy owner membership" do
    policy = MembershipPolicy.new(@admin_user, @owner_membership)
    assert_not policy.destroy?
  end

  test "lead cannot destroy any membership" do
    policy = MembershipPolicy.new(@lead_user, @scout_membership)
    assert_not policy.destroy?
  end

  test "scout cannot destroy any membership" do
    policy = MembershipPolicy.new(@scout_user, @lead_membership)
    assert_not policy.destroy?
  end

  # --- bulk_update? ---

  test "admin can bulk update memberships" do
    policy = MembershipPolicy.new(@admin_user, Membership)
    assert policy.bulk_update?
  end

  test "lead cannot bulk update memberships" do
    policy = MembershipPolicy.new(@lead_user, Membership)
    assert_not policy.bulk_update?
  end

  test "scout cannot bulk update memberships" do
    policy = MembershipPolicy.new(@scout_user, Membership)
    assert_not policy.bulk_update?
  end

  # --- bulk_destroy? ---

  test "admin can bulk destroy memberships" do
    policy = MembershipPolicy.new(@admin_user, Membership)
    assert policy.bulk_destroy?
  end

  test "lead cannot bulk destroy memberships" do
    policy = MembershipPolicy.new(@lead_user, Membership)
    assert_not policy.bulk_destroy?
  end

  test "scout cannot bulk destroy memberships" do
    policy = MembershipPolicy.new(@scout_user, Membership)
    assert_not policy.bulk_destroy?
  end
end
