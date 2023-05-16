class SubjectType < ApplicationRecord
  # SCHEMA:
  # t.bigint "study_plan_id", null: false
  # t.string "name"
  # t.string "code"
  # t.integer "required_credits", default: 0, null: false  

  # ASSOCIATIONS:
  belongs_to :study_plan

  # VALIDATIONS:
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates_format_of :code, with: /\A[a-z]+\z/i
  validates :required_credits, presence: true, numericality: { only_integer: true, in: 0..200 }

  # RAILS_ADMIN:
  rails_admin do
    edit do
      field :code do
        html_attributes do
          {onInput: "$(this).val($(this).val().toUpperCase().replace(/[^A-Z]/g,'').substr(0, 1))"}
        end
        help 'Una sola letra permitida'
      end
      field :name do
        html_attributes do
          {onInput: "$(this).val($(this).val().toUpperCase().replace(/[^A-Z]/g,''))"}
        end
      end
      field :required_credits
    end
  end

end
