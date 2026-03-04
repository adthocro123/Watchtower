require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:team_254)
    @owner_user = users(:owner_user)
    @admin_user = users(:admin_user)
    @lead_user = users(:lead_user)
    @scout_user = users(:scout_user)

    @owner_membership = memberships(:owner_membership)
    @admin_membership = memberships(:admin_membership)
    @lead_membership = memberships(:lead_membership)
    @scout_membership = memberships(:scout_membership)
  end

  # --- update (PATCH) ---

  test "admin can update a member role" do
    sign_in_as @admin_user
    switch_organization @organization

    patch organization_membership_path(@organization, @scout_membership),
          params: { membership: { role: "analyst" } }

    assert_redirected_to @organization
    assert_equal "analyst", @scout_membership.reload.role
  end

  test "admin cannot update owner role" do
    sign_in_as @admin_user
    switch_organization @organization

    patch organization_membership_path(@organization, @owner_membership),
          params: { membership: { role: "scout" } }

    # Should be blocked by Pundit
    assert_redirected_to root_path
    assert_equal "owner", @owner_membership.reload.role
  end

  test "lead cannot update any role" do
    sign_in_as @lead_user
    switch_organization @organization

    patch organization_membership_path(@organization, @scout_membership),
          params: { membership: { role: "analyst" } }

    assert_redirected_to root_path
    assert_equal "scout", @scout_membership.reload.role
  end

  test "scout cannot update any role" do
    sign_in_as @scout_user
    switch_organization @organization

    patch organization_membership_path(@organization, @lead_membership),
          params: { membership: { role: "scout" } }

    assert_redirected_to root_path
    assert_equal "lead", @lead_membership.reload.role
  end

  test "admin cannot assign owner role via update" do
    sign_in_as @admin_user
    switch_organization @organization

    patch organization_membership_path(@organization, @scout_membership),
          params: { membership: { role: "owner" } }

    assert_redirected_to @organization
    assert_equal "scout", @scout_membership.reload.role
    assert_includes flash[:alert], "Invalid role"
  end

  test "admin cannot assign owner role via bulk update" do
    sign_in_as @admin_user
    switch_organization @organization

    post bulk_update_organization_memberships_path(@organization),
         params: { membership_ids: [ @scout_membership.id ], role: "owner" }

    assert_redirected_to @organization
    assert_equal "scout", @scout_membership.reload.role
    assert_includes flash[:alert], "Invalid role"
  end

  test "admin can demote themselves when another admin exists" do
    sign_in_as @admin_user
    switch_organization @organization

    # Promote lead to admin so there are two admins
    @lead_membership.update!(role: :admin)

    patch organization_membership_path(@organization, @admin_membership),
          params: { membership: { role: "scout" } }

    assert_redirected_to @organization
    assert_equal "scout", @admin_membership.reload.role
  end

  test "last admin cannot demote themselves" do
    sign_in_as @admin_user
    switch_organization @organization

    patch organization_membership_path(@organization, @admin_membership),
          params: { membership: { role: "scout" } }

    assert_redirected_to @organization
    assert_equal "admin", @admin_membership.reload.role
    assert_includes flash[:alert], "last admin"
  end

  test "last admin cannot be removed" do
    sign_in_as @owner_user
    switch_organization @organization

    assert_no_difference "Membership.count" do
      delete organization_membership_path(@organization, @admin_membership)
    end

    assert_redirected_to @organization
    assert_includes flash[:alert], "last admin"
  end

  test "bulk update cannot demote the last admin" do
    sign_in_as @owner_user
    switch_organization @organization

    post bulk_update_organization_memberships_path(@organization),
         params: { membership_ids: [ @admin_membership.id ], role: "scout" }

    assert_redirected_to @organization
    assert_equal "admin", @admin_membership.reload.role
    assert_includes flash[:alert], "last admin"
  end

  test "bulk destroy cannot remove the last admin" do
    sign_in_as @owner_user
    switch_organization @organization

    assert_no_difference "Membership.count" do
      post bulk_destroy_organization_memberships_path(@organization),
           params: { membership_ids: [ @admin_membership.id ] }
    end

    assert_redirected_to @organization
    assert_includes flash[:alert], "last admin"
  end

  # --- destroy (DELETE) ---

  test "admin can remove a non-owner member" do
    sign_in_as @admin_user
    switch_organization @organization

    assert_difference "Membership.count", -1 do
      delete organization_membership_path(@organization, @scout_membership)
    end

    assert_redirected_to @organization
  end

  test "admin cannot remove the owner" do
    sign_in_as @admin_user
    switch_organization @organization

    assert_no_difference "Membership.count" do
      delete organization_membership_path(@organization, @owner_membership)
    end

    assert_redirected_to root_path
  end

  test "lead cannot remove members" do
    sign_in_as @lead_user
    switch_organization @organization

    assert_no_difference "Membership.count" do
      delete organization_membership_path(@organization, @scout_membership)
    end

    assert_redirected_to root_path
  end

  test "scout cannot remove members" do
    sign_in_as @scout_user
    switch_organization @organization

    assert_no_difference "Membership.count" do
      delete organization_membership_path(@organization, @lead_membership)
    end

    assert_redirected_to root_path
  end

  # --- bulk_update (POST) ---

  test "admin can bulk update roles" do
    sign_in_as @admin_user
    switch_organization @organization

    post bulk_update_organization_memberships_path(@organization),
         params: { membership_ids: [ @scout_membership.id, @lead_membership.id ], role: "analyst" }

    assert_redirected_to @organization
    assert_equal "analyst", @scout_membership.reload.role
    assert_equal "analyst", @lead_membership.reload.role
  end

  test "bulk update skips owner memberships" do
    sign_in_as @admin_user
    switch_organization @organization

    post bulk_update_organization_memberships_path(@organization),
         params: { membership_ids: [ @owner_membership.id, @scout_membership.id ], role: "analyst" }

    assert_redirected_to @organization
    assert_equal "owner", @owner_membership.reload.role
    assert_equal "analyst", @scout_membership.reload.role
  end

  test "bulk update rejects invalid role" do
    sign_in_as @admin_user
    switch_organization @organization

    post bulk_update_organization_memberships_path(@organization),
         params: { membership_ids: [ @scout_membership.id ], role: "superadmin" }

    assert_redirected_to @organization
    assert_equal "scout", @scout_membership.reload.role
    assert_includes flash[:alert], "Invalid role"
  end

  test "lead cannot bulk update" do
    sign_in_as @lead_user
    switch_organization @organization

    post bulk_update_organization_memberships_path(@organization),
         params: { membership_ids: [ @scout_membership.id ], role: "analyst" }

    assert_redirected_to root_path
    assert_equal "scout", @scout_membership.reload.role
  end

  # --- bulk_destroy (POST) ---

  test "admin can bulk remove members" do
    sign_in_as @admin_user
    switch_organization @organization

    assert_difference "Membership.count", -2 do
      post bulk_destroy_organization_memberships_path(@organization),
           params: { membership_ids: [ @scout_membership.id, @lead_membership.id ] }
    end

    assert_redirected_to @organization
  end

  test "bulk destroy skips owner membership" do
    sign_in_as @admin_user
    switch_organization @organization

    assert_difference "Membership.count", -1 do
      post bulk_destroy_organization_memberships_path(@organization),
           params: { membership_ids: [ @owner_membership.id, @scout_membership.id ] }
    end

    assert_redirected_to @organization
    assert Membership.exists?(@owner_membership.id), "Owner membership should not be deleted"
  end

  test "lead cannot bulk destroy" do
    sign_in_as @lead_user
    switch_organization @organization

    assert_no_difference "Membership.count" do
      post bulk_destroy_organization_memberships_path(@organization),
           params: { membership_ids: [ @scout_membership.id ] }
    end

    assert_redirected_to root_path
  end

  # --- owner as actor ---

  test "owner can update a member role" do
    sign_in_as @owner_user
    switch_organization @organization

    patch organization_membership_path(@organization, @scout_membership),
          params: { membership: { role: "analyst" } }

    assert_redirected_to @organization
    assert_equal "analyst", @scout_membership.reload.role
  end

  test "owner can remove a non-owner member" do
    sign_in_as @owner_user
    switch_organization @organization

    assert_difference "Membership.count", -1 do
      delete organization_membership_path(@organization, @scout_membership)
    end

    assert_redirected_to @organization
  end

  test "owner can bulk update roles" do
    sign_in_as @owner_user
    switch_organization @organization

    post bulk_update_organization_memberships_path(@organization),
         params: { membership_ids: [ @scout_membership.id, @lead_membership.id ], role: "analyst" }

    assert_redirected_to @organization
    assert_equal "analyst", @scout_membership.reload.role
    assert_equal "analyst", @lead_membership.reload.role
  end

  test "owner can bulk remove members" do
    sign_in_as @owner_user
    switch_organization @organization

    assert_difference "Membership.count", -2 do
      post bulk_destroy_organization_memberships_path(@organization),
           params: { membership_ids: [ @scout_membership.id, @lead_membership.id ] }
    end

    assert_redirected_to @organization
  end
end
