class Course < ApplicationRecord
  # SCHEMA:
  # t.bigint "academic_process_id", null: false
  # t.bigint "subject_id", null: false
  # t.boolean "offer_as_pci"
  # t.string "name"
  # Course.all.map{|ap| ap.update(name: 'x')}  

  # ASSOCIATIONS:
  # belongs_to
  belongs_to :academic_process
  has_one :period, through: :academic_process
  has_one :school, through: :academic_process
  belongs_to :subject
  
  # has_many
  has_many :sections, dependent: :destroy
  has_many :academic_records, through: :sections

  #VALIDATIONS:
  validates :subject, presence: true
  validates :academic_process, presence: true

  # validates_uniqueness_of :subject_id, scope: [:academic_process_id], message: 'Ya existe la asignatura para el proceso académico.', field_name: false

  scope :pcis, -> {where(offer_as_pci: true)}
  scope :order_by_subject_ordinal, -> {joins(:subject).order('subjects.ordinal': :asc)}
  scope :order_by_subject_code, -> {joins(:subject).order('subjects.code': :asc)}

  # ORIGINAL CON LEFT JOIN
  # scope :without_sections, -> {joins("LEFT JOIN sections s ON s.course_id = courses.id").where(s: {course_id: nil})}
  
  # OPTIMO CON LEFT OUTER JOIN
  scope :without_sections, -> {left_joins(:sections).where('sections.course_id': nil)}


  # CALLBACKS:
  before_save :set_name

  def get_name
    "#{self.academic_process.name}-#{self.subject.desc}" if self.period and self.school and self.subject
  end

  def total_sections
    sections.count
  end

  def subject_desc_with_pci
    if offer_as_pci
      self.subject.description_code_with_school
    else
      self.subject.description_code
    end
  end

  rails_admin do
    visible false
    navigation_label 'Inscripciones'
    navigation_icon 'fa-solid fa-shapes'

    list do
      fields :academic_process, :subject
      field :total_sections
    end

    show do
      fields :academic_process, :subject, :sections
    end

    edit do
      fields :academic_process, :subject#, :sections
    end

    export do
      fields :academic_process, :subject
    end


  end
  
  private
    def set_name
      self.name = self.get_name
    end
end
