class ParentArea < ApplicationRecord
	validates :name, presence: true
	validates :school, presence: true

	belongs_to :school

	has_many :areas

	rails_admin do
		visible do
			bindings[:controller].current_user&.admin&.authorized_read? Area
		end

		navigation_label 'Config General'
		navigation_icon 'fa-regular fa-person-breastfeeding'
		weight 0

		edit do
			fields :name, :school, :areas
		end

		list do
			fields :name, :school, :areas
		end
	end

end
