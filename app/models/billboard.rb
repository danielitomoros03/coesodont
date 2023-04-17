class Billboard < ApplicationRecord
	# HISTORY:
	has_paper_trail on: [:create, :destroy, :update]

	before_create :paper_trail_create
	before_destroy :paper_trail_destroy
	before_update :paper_trail_update

	# Rich Text
    has_rich_text :content

    scope :activas, -> {where(active: true)}

    validates :content, presence: true

	def activada_valor
		activa ? 'Activada' : 'Desactivada'
	end


	rails_admin do
		navigation_icon 'fa-regular fa-calendar-alt'

		edit do
			field :active
			field :content
		end		
	end
	

	private

		def paper_trail_update
			changed_fields = self.changes.keys - ['created_at', 'updated_at']
			object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
			self.paper_trail_event = "¡#{object} actualizada en #{changed_fields.to_sentence}"
		end  

		def paper_trail_create
			object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
			self.paper_trail_event = "¡Cartelera creada!"
		end  

		def paper_trail_destroy
			object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
			self.paper_trail_event = "¡Cartelera eliminada!"
		end
		
end
