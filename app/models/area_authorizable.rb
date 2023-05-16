class AreaAuthorizable < ApplicationRecord
	# SCHEMA:
	# t.string "name", null: false
	# t.string "description"
	# t.string "icon"

	# ASSOCIATIONS:
	has_many :authorizables, dependent: :destroy
	accepts_nested_attributes_for :authorizables, allow_destroy: true#, reject_if: proc { |attributes| attributes['area_authorizable_id'].blank? }

	#VALIDATIONS:
	validates :name, presence: true, uniqueness: true

	# FUNTIONS:

	def can_all? admin_id
		can = true
		authorizables.each do |athble|
			athd = Authorized.where(admin_id: admin_id, authorizable_id: athble.id).first
			can = false if !(athd and athd.can_all?)
		end
		return can
	end

	# RAILS_ADMIN:
	rails_admin do
		# visible false
		navigation_label 'DESARROLLO'
		navigation_icon 'fa-solid fa-object-group'
		
		edit do
			fields :name, :description, :icon, :authorizables

		end
		list do
		end
	end
end
