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
  has_one :area, through: :subject
  
  # has_many
  has_many :sections, dependent: :destroy
  has_many :academic_records, through: :sections

  #VALIDATIONS:
  validates :subject, presence: true
  validates :academic_process, presence: true

  # validates_uniqueness_of :subject_id, scope: [:academic_process_id], message: 'Ya existe la asignatura para el proceso académico.', field_name: false

  # SCOPE
  scope :pcis, -> {where(offer_as_pci: true)}
  scope :order_by_subject_ordinal, -> {joins(:subject).order('subjects.ordinal': :asc)}
  scope :order_by_subject_code, -> {joins(:subject).order('subjects.code': :asc)}

  scope :custom_search, -> (keyword) {joins(:period, :subject).where("subjects.name ILIKE '%#{keyword}%' OR subjects.code ILIKE '%#{keyword}%' OR periods.name ILIKE '%#{keyword}%'") }

  # ORIGINAL CON LEFT JOIN
  # scope :without_sections, -> {joins("LEFT JOIN sections s ON s.course_id = courses.id").where(s: {course_id: nil})}
  
  # OPTIMO CON LEFT OUTER JOIN
  scope :without_sections, -> {left_joins(:sections).where('sections.course_id': nil)}


  # CALLBACKS:
  before_save :set_name

  def get_name
    "#{self.academic_process.name}-#{self.subject.desc}" if self.period and self.school and self.subject
  end

  def qualifications_average
    if total_academic_records > 0
      values = academic_records.joins(:qualifications).sum('qualifications.value')
      (values.to_f/total_academic_records.to_f).round(2)
    end
  end

  def total_sections
    sections.count
  end

  def total_academic_records
    academic_records.count
  end

  def total_sc
    academic_records.sin_calificar.count
  end

  def total_aprobados
    academic_records.not_perdida_por_inasistencia.aprobado.count
  end

  def total_aplazados
    academic_records.not_perdida_por_inasistencia.aplazado.count
  end

  def total_retirados
    academic_records.retirado.count
  end

  def total_pi
    academic_records.perdida_por_inasistencia.count
  end 

  def subject_desc_with_pci
    if offer_as_pci
      self.subject.description_code_with_school
    else
      self.subject.description_code
    end
  end

  rails_admin do
    # visible false
    navigation_label 'Gestión Periódica'
    navigation_icon 'fa-solid fa-shapes'
    weight -2

    list do
      sort_by ['courses.name']
      search_by :custom_search
      field :academic_process do
        label 'Period'
        column_width 100
        pretty_value do
          value.period.name
        end
      end
      field :subject
      field :total_sections do
        label 'T. Sec'
        pretty_value do
          ApplicationController.helpers.label_status('bg-info', value)
        end
      end
      field :total_academic_records do
        label 'Ins'
        pretty_value do
          # %{<a href='/admin/academic_record?query=#{bindings[:object].name}'><span class='badge bg-info'>#{ApplicationController.helpers.label_status('bg-info', value)}</span></a>}.html_safe
          ApplicationController.helpers.label_status('bg-info', value)

        end
      end
      field :total_sc do
        label 'SC'
        help 'Sin Calificar'
        pretty_value do
          ApplicationController.helpers.label_status('bg-secondary', value)
        end
      end
      field :total_aprobados do
        label 'A'
        help 'Aprobado'
        pretty_value do
          ApplicationController.helpers.label_status('bg-success', value)
        end
      end
      field :total_aplazados do
        label 'AP'
        pretty_value do
          ApplicationController.helpers.label_status('bg-danger', value)
        end        
      end
      field :total_retirados do
        label 'Ret'
        pretty_value do
          ApplicationController.helpers.label_status('bg-secondary', value)
        end        
      end 
      field :total_pi do
        label 'PI'
        pretty_value do
          ApplicationController.helpers.label_status('bg-danger', value)
        end        
      end 
      field :qualifications_average do
        label 'Prom'
        pretty_value do
          ApplicationController.helpers.label_status('bg-info', value)
        end         
      end      
    end

    show do
      fields :academic_process, :subject, :sections
    end

    edit do
      fields :academic_process, :subject#, :sections
    end

    export do
      fields :academic_process, :period, :subject, :area
      field :total_sections do
        label 'T. Sec'
      end
      field :total_academic_records do
        label 'Ins'
      end
      field :total_sc do
        label 'SC'
      end
      field :total_aprobados do
        label 'A'
        help 'Aprobado'
      end
      field :total_aplazados do
        label 'AP'
      end
      field :total_retirados do
        label 'Ret'
      end 
      field :total_pi do
        label 'PI'
      end 
      field :qualifications_average do
        label 'PROM'
      end

    end


  end
  
  private
    def set_name
      self.name = self.get_name
    end
end
