class RequirementByLevel < ApplicationRecord
  # ASSOSIATIONS:
  belongs_to :study_plan
  belongs_to :subject_type

  # VALIDATIONS:
  validates :study_plan, presence: true
  validates :subject_type, presence: true
  validates :level, presence: true
  validates :required_subjects, presence: true
  validates_uniqueness_of :study_plan_id, scope: [:level, :subject_type_id], message: 'la relación ya existe', field_name: false

  rails_admin do
    visible false
  end

end
