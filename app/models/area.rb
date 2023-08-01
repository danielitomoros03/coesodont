class Area < ApplicationRecord
  # SCHEMA:
  # t.string "name", null: false
  # t.bigint "school_id", null: false
  # t.bigint "parent_area_id"
  
  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update


  # ASSOCITATIONS:
  belongs_to :school
  belongs_to :parent_area
  # belongs_to :other_parent, optional: true, class_name: 'Area', foreign_key: :other_parent_id
  has_many :admins, as: :env_authorizable 

  has_many :subareas, class_name: 'Area', foreign_key: :parent_area_id

  has_many :subjects, dependent: :destroy
  # accepts_nested_attributes_for :subjects

  # VALIDATIONS:
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :school_id, presence: true

  # SCOPES:
  scope :main, -> {where(parent_area_id: nil)}
  scope :catedras, -> {where.not(parent_area_id: nil)}
  scope :names, -> {select(:name).map{|ar| ar.name}}

  # CALLBACKS:
  before_save :clean_name

  # HOOKS:
  def clean_name
    self.name.strip!
    self.name.upcase!
  end

  # FUNCTIONS:

  def description
    "#{self.id}: #{self.name}"
  end

  def total_subjects
    subjects.count
  end

  def total_subareas
    subareas.count
  end

  rails_admin do
    visible do
      bindings[:controller].current_user&.admin?
    end
    navigation_label 'Config General'
    navigation_icon 'fa-regular fa-brain'
    weight 1

    list do
      scopes [:catedras]
      field :name
      field :parent_area
      # field :other_parent
      field :total_subjects do
        label 'Total Asignaturas'
      end

      field :total_subareas do
        label 'Total Subareas'
      end
    end
    show do
      field :name
      field :parent_area
      # field :other_parent
      field :subjects
      field :subareas
    end 

    edit do
      field :name

      field :parent_area do
        inline_edit false
      end

      field :other_parent do
        read_only true
      end

    end 

    modal do
      field :name
      exclude_fields :parent_area
    end


    export do
      fields :name
    end

    import do
      fields :name, :school_id 
    end

  end

  after_initialize do
    if new_record?
      self.school_id ||= School.first.id
    end
  end

  private


    def paper_trail_update
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} actualizada!"
    end  

    def paper_trail_create
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} registrada!"
    end  

    def paper_trail_destroy
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡Asignatura eliminada!"
    end  

end
