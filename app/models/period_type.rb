class PeriodType < ApplicationRecord
	# SCHEMA:
	# t.string "code"
    # t.string "name"

	# ASSOCIATIONS:
	has_many :periods

	default_scope { order(name: :desc) }

	# VALIDATIONS:
	validates :code, presence: true
	validates :name, presence: true

	rails_admin do
		visible false
		navigation_icon 'fa-regular fa-clock'

		list do
			fields :code, :name
		end

		show do
			fields :code, :name
		end

		edit do
			fields :code, :name
		end

		export do
			fields :code, :name
		end		
	end
end
