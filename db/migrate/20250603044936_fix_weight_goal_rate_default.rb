class FixWeightGoalRateDefault < ActiveRecord::Migration[8.0]
  def up
    change_column_default :settings, :weight_goal_rate, from: "0.0", to: 0.0
  end

  def down
    change_column_default :settings, :weight_goal_rate, from: 0.0, to: "0.0"
  end
end
