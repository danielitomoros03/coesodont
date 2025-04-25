class AddTotalCreditsToStudyPlan < ActiveRecord::Migration[7.0]
  def change
    add_column :study_plans, :total_credits, :integer, default: 0
  end
end
