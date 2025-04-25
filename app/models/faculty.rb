class Faculty < ApplicationRecord
  #SCHEMA:
  # t.string "code"
  # t.string "name"

  validates :code, presence: true, uniqueness: {case_sensitive: false}
  validates :name, presence: true, uniqueness: {case_sensitive: false}

  before_save :clean_name_and_code

  # HOOKS:
  def clean_name_and_code
    self.name.delete! '^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
    self.name.strip!
    self.name.upcase!

    self.code.delete! '^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ'
    self.code.strip!
    self.code.upcase!
  end

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

	# ASSOCIATIONS:
	# has_many:
	has_many :admins, as: :env_authorizable, dependent: :destroy
	has_many :schools, dependent: :destroy
	has_many :academic_processes, through: :schools
	has_many :periods, through: :academic_processes
	# has_many :grades, through: :schools
	# has_many :students, through: :grades
	has_one_attached :logo
	# VALIDATIONS:
	validates :code, presence: true, uniqueness: {case_sensitive: false}
	validates :name, presence: true, uniqueness: {case_sensitive: false}

	rails_admin do
		navigation_label 'Config General'
		navigation_icon 'fa-regular fa-building-columns'
		visible false

		list do
			exclude_fields :created_at, :updated_at
		end

		show do
			fields :code, :name, :logo
		end


		edit do
			field :code do
				html_attributes do
					{:length => 3, :size => 3, :onInput => "$(this).val($(this).val().toUpperCase().replace(/[^A-Za-z]/g,''))"}
				end
			end
			field :name do
				html_attributes do
					{:onInput => "$(this).val($(this).val().toUpperCase())"}
				end				
			end
			field :logo
		end
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
      self.paper_trail_event = "¡Facultad eliminada!"
    end

end
