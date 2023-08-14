class SubjectType < ApplicationRecord
  # SCHEMA:
  # t.bigint "study_plan_id", null: false
  # t.string "name"
  # t.string "code"
  # t.integer "required_credits", default: 0, null: false 
  
  # HISTORY:
	has_paper_trail on: [:create, :destroy, :update]

	before_create :paper_trail_create
	before_destroy :paper_trail_destroy
	before_update :paper_trail_update

  # ASSOCIATIONS:
  belongs_to :study_plan

  # VALIDATIONS:
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates_format_of :code, with: /\A[a-z]+\z/i
  validates :required_credits, presence: true, numericality: { only_integer: true, in: 0..230 }

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

  def desc_pluralize
    "#{self.name&.downcase&.pluralize&.titleize} (#{self.code})"
  end  

  private
		def paper_trail_update
			# changed_fields = self.changes.keys - ['created_at', 'updated_at']
			object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
			# self.paper_trail_event = "¡#{object} actualizado en #{changed_fields.to_sentence}"
			self.paper_trail_event = "¡#{object} actualizada!"
		end  

		def paper_trail_create
			object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
			self.paper_trail_event = "¡#{object} registrada!"
		end  

		def paper_trail_destroy
			object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
			self.paper_trail_event = "¡Tipo de Asignatura eliminada!"
		end

end
