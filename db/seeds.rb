# frozen_string_literal: true

puts "Seeding database..."

# --- Game Configuration for 2026 REBUILT ---
game_config = GameConfig.find_or_create_by!(year: 2026) do |gc|
  gc.game_name = "REBUILT presented by Haas"
  gc.active = true
  gc.config = {
    year: 2026,
    game_name: "REBUILT presented by Haas",
    simple_shooting_mode: true,
    scoring: {
      fuel_point_value: 1,
      auton_climb_points: 10,
      climb_points: { "None" => 0, "L1" => 10, "L2" => 20, "L3" => 30 }
    },
    phases: {
      auton: {
        fields: [
          { key: "auton_fuel_made", type: "counter", label: "Fuel Made", color: "green" },
          { key: "auton_fuel_missed", type: "counter", label: "Fuel Missed", color: "red" },
          { key: "auton_climb", type: "toggle", label: "Auton Climb (10 pts)", default: false }
        ],
        actions: [
          { key: "bump", label: "Bump", icon: "collision" },
          { key: "trench", label: "Trench", icon: "road" },
          { key: "intake", label: "Intake", icon: "download" }
        ]
      },
      teleop: {
        fields: [
          { key: "teleop_fuel_made", type: "counter", label: "Fuel Made", color: "green" },
          { key: "teleop_fuel_missed", type: "counter", label: "Fuel Missed", color: "red" }
        ]
      },
      endgame: {
        fields: [
          { key: "endgame_fuel_made", type: "counter", label: "Fuel Made", color: "green" },
          { key: "endgame_fuel_missed", type: "counter", label: "Fuel Missed", color: "red" },
          { key: "endgame_climb", type: "select", label: "Climb Level", options: %w[None L1 L2 L3], default: "None" }
        ]
      }
    },
    auton_actions_tracked: %w[bump trench intake]
  }
end
puts "  Game config: #{game_config.game_name} (#{game_config.year})"

# --- Admin User ---
admin = User.find_or_create_by!(email: "admin@scoutrail.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Admin"
  u.last_name = "User"
  u.team_number = 1234
end
admin.add_role(:admin) unless admin.has_role?(:admin)
puts "  Admin user: #{admin.email} (role: admin)"

# --- Scout User ---
scout = User.find_or_create_by!(email: "scout@scoutrail.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Scout"
  u.last_name = "User"
  u.team_number = 1234
end
scout.add_role(:scout) unless scout.has_role?(:scout)
puts "  Scout user: #{scout.email} (role: scout)"

# --- Summary ---
puts ""
puts "Seed complete!"
puts "  Game configs: #{GameConfig.count}"
puts "  Users: #{User.count}"
puts "  Admin users: #{User.with_role(:admin).count}"
puts "  Scout users: #{User.with_role(:scout).count}"
