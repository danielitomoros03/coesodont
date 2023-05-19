class SubjectLink < ApplicationRecord
  # t.bigint "prelate_subject_id", null: false
  # t.bigint "depend_subject_id", null: false

  belongs_to :prelate_subject, class_name: 'Subject', foreign_key: :prelate_subject_id
  belongs_to :depend_subject, class_name: 'Subject', foreign_key: :depend_subject_id

  validates_uniqueness_of :prelate_subject_id, scope: [:depend_subject_id], message: 'la relación ya existe', field_name: false
  validates :prelate_subject_id, presence: true
  validates :depend_subject_id, presence: true

  validates_with NestedDependencyValidator, field_name: false

  scope :in_prelation, -> (aprobadas_ids) {where(prelate_subject_id: aprobadas_ids) }
  scope :not_in_dependency, -> (aprobadas_ids) {where.not(depend_subject_id: aprobadas_ids) }

  def self.subject_tree ids
    auxs = SubjectLink.where(id: ids).joins(:subject).select('subjects.*')
  end

end
