class ParentArea < ApplicationRecord
	validates :name, presence: true
	validates :school, presence: true

	belongs_to :school

	has_many :areas, dependent: :restrict_with_error

	rails_admin do
		visible do
			bindings[:controller].current_user&.admin&.authorized_read? 'Subject'
		end

		navigation_label 'Config General'
		navigation_icon 'fa-regular fa-person-breastfeeding'
		weight 0

		edit do

			field :name do
				html_attributes do
					{:onInput => "$(this).val($(this).val().toUpperCase())"}
				end				
			end			
			field :school do
				inline_edit false 
			end
			field :areas do
				inline_add false
			end
		end

		list do
			fields :name, :school, :areas
		end
	end

end
