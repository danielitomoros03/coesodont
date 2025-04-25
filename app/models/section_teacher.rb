class SectionTeacher < ApplicationRecord
  self.table_name = 'sections_teachers'

  belongs_to :section
  belongs_to :teacher#, primary_key: :user_id

  validates_uniqueness_of :teacher_id, scope: [:section_id], message: 'Profesor secundario ya existe para esta sección', field_name: false

  validates :section_id,  presence: true
  validates :teacher_id,  presence: true

end