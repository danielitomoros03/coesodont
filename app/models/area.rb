class Area < ApplicationRecord
  # SCHEMA:
  # t.string "name", null: false
  # t.bigint "school_id", null: false
  # t.bigint "parent_area_id"
  
  # ASSOCITATIONS:
  belongs_to :school
  belongs_to :parent_area, optional: true, class_name: 'Area', primary_key: :parent_area_id
  has_many :admins, as: :env_authorizable 

  has_many :subareas, class_name: 'Area', foreign_key: :parent_area_id

  has_many :subjects
  # accepts_nested_attributes_for :subjects

  # VALIDATIONS:
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :school_id, presence: true

  # SCOPES:
  scope :main, -> {where(parent_area_id: nil)}
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
    visible false
    navigation_label 'Config General'
    navigation_icon 'fa-regular fa-brain'

    list do
      field :name
      field :parent_area
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
      field :subjects
      field :subareas
    end 

    edit do
      field :name
      field :parent_area
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

end
