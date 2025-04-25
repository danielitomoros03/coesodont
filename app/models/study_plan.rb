class StudyPlan < ApplicationRecord
  # SCHEMA:
  # t.string "code"
  # t.string "name"
  # t.integer "madatory_credits"
  # t.integer "optative_credits"
  # t.integer "elective_credits"
  # t.bigint "school_id", null: false 
  # t.bigint "levels", null: false 
  # t.bigint "modality", null: false 
  
  
  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  # ASSOCIATIONS:
  belongs_to :school
  has_many :grades, dependent: :destroy
  has_many :requirement_by_levels, dependent: :destroy

  has_many :subject_types, dependent: :destroy
  accepts_nested_attributes_for :subject_types, allow_destroy: true  
  
  has_many :mentions, dependent: :destroy
  accepts_nested_attributes_for :mentions, allow_destroy: true  

  # VALIDATIONS:
  validates :code, presence: true, uniqueness: {case_sensitive: false}
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :subject_types, presence: true
  validates :school, presence: true

  # ENUMS:
  enum modality: [:Anual, :Semestral]

  # CALLBACKS:
  after_initialize :set_unique_school
  before_save :clean_values

  # HOOKS:
  def clean_values
    self.name.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
    self.name.strip!
    self.code.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ'
    self.code.strip!
    self.name.upcase!
    self.code.upcase!
  end

  # FUNTIONS:
  # def initialization
  #   requirement_by_levels
  # end

  def modality_to_tipo
    Anual? ? 'Año' : 'Semestral'
  end

  def desc
    "(#{code}) #{name}"
  end

  # def desc_credits
  #   "(Créditos Requeridos) #{mandatory_credits}"
  # end

  rails_admin do
    navigation_label 'Config General'
    navigation_icon 'fa-solid fa-award'
    weight -2

    show do
      fields :school, :code, :modality, :levels, :name, :subject_types, :mentions
    end

    list do
      fields :code, :name, :modality, :levels, :subject_types, :mentions do
        sortable false
        filterable false
        searchable false
        queryable false
      end
    end

    export do
      fields :code, :name, :modality, :subject_types
    end

    edit do
      field :school
      field :code do 
        html_attributes do
          {:length => 8, :size => 8, :onInput => "$(this).val($(this).val().toUpperCase().replace(/[^a-zA-Z0-9\u00f1\u00d1 ]/g,''))"}
        end
      end
      fields :name, :modality, :levels, :subject_types, :mentions

    end

  end

  def set_unique_school
    self.school_id = School.first.id if School.count.eql? 1
  end

  private


    def paper_trail_update
      # changed_fields = self.changes.keys - ['created_at', 'updated_at']
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      # self.paper_trail_event = "¡#{object} actualizado en #{changed_fields.to_sentence}"
      self.paper_trail_event = "¡#{object} actualizado!"
    end  

    def paper_trail_create
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} registrado!"
    end  

    def paper_trail_destroy
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡Plan de Estudio eliminado!"
    end


end
