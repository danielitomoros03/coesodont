class Authorizable < ApplicationRecord
  # SCHEMA:
  # t.bigint "area_authorizable_id", null: false
  # t.string "klazz", null: false
  # t.string "description"
  # t.string "icon"

  IMPORTABLES = ['Student', 'Teacher', 'Subject', 'Section', 'AcademicRecord']
  UNEXPORTABLES = ['School', 'Faculty', 'StudyPlan']
  UNDELETABLES = ['School', 'StudyPlan', 'Faculty', 'EnrollAcademicProcess']
  UNCREABLES = ['School', 'Faculty']
  # ASSOCIATIONS:
  belongs_to :area_authorizable

  # VALIDATIONS:
  validates :klazz, presence: true, uniqueness: true

  # FUNCTIONS:
  def name
    ApplicationController.helpers.translate_model klazz.tableize.singularize if klazz
  end
  # RAILS_ADMIN:
  rails_admin do
    # visible false
    navigation_label 'DESARROLLO'
    navigation_icon 'fa-solid fa-door-open'


    edit do
      field :klazz #do
      #   formatted_value do
      #     objetos = ApplicationRecord.descendants

      #     bindings[:view].collection_select(:authorizable, :name, objetos, :name, :name, {class: "text-field form-control", required: true}) << value
          
      #   end
      # end
      fields :description, :icon
    end
  end
end
