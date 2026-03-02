module Scoring
  extend ActiveSupport::Concern

  FUEL_POINT_VALUE = 1
  CLIMB_POINTS = {
    "None" => 0,
    "L1" => 10,
    "L2" => 20,
    "L3" => 30
  }.freeze
  AUTON_CLIMB_POINTS = 10
end
