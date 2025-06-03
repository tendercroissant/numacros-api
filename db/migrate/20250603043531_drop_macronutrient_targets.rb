class DropMacronutrientTargets < ActiveRecord::Migration[8.0]
  def change
    drop_table :macronutrient_targets
  end
end
