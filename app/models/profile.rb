class Profile < ApplicationRecord
	#SCHEMA:
	# t.string "name"

	# ASSOCIATIONS:
	has_many :admins

	# VALIDATIONS:
	validates :name, presence: true

end
