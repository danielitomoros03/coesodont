class AcademicProcess < ApplicationRecord
  # SCHEMA:
    # t.bigint "school_id", null: false
    # t.bigint "period_id", null: false
    # t.integer "max_credits"
    # t.integer "max_subjects"
    # t.integer "modality"
    # t.bigint "process_before_id"
    # t.string "name"
    # AcademicProcess.all.map{|ap| ap.update(name: 'x')}

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  has_rich_text :enroll_instructions

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  # ASSOCIATIONS:
  #belongs_to:
  belongs_to :school
  belongs_to :period
  has_one :period_type, through: :period

  belongs_to :process_before, class_name: 'AcademicProcess', optional: true

  #has_many:
  has_many :enrollment_days, dependent: :destroy
  has_many :enroll_academic_processes, dependent: :destroy
  has_many :grades, through: :enroll_academic_processes
  has_many :students, through: :grades
  has_many :courses
  has_many :sections, through: :courses
  has_many :academic_records, through: :sections
  has_many :subjects, through: :courses

  # ENUMERIZE:
  enum modality: [:Semestral, :Anual]

  #VALIDATIONS:
  validates :school, presence: true
  validates :period, presence: true
  validates :modality, presence: true
  validates :max_credits, presence: true
  validates :max_subjects, presence: true

  validates_uniqueness_of :school, scope: [:period], message: 'Proceso academico ya creado', field_name: false

  # SCOPE:
  default_scope { order(name: :desc) }

  scope :without_enroll_academic_processes, -> {left_joins(:enroll_academic_processes).where('enroll_academic_processes.academic_process_id': nil)}

  # CALLBACKS:
  before_save :set_name

  def subject_active_for_this? subject_id
    subjects.ids.include?(subject_id)
  end


  def period_name
    period.name if period
  end

  def exame_type
    "#{period.period_type.name.upcase} #{modality.upcase}" if (period and period.period_type and modality)
  end

  def default_value_by_import
    max_credits = 24
    max_subject = 5
    modality = :semestral
  end

  def short_desc
    "#{self.school.short_name} #{self.period.name}" if (self.school and self.period)
  end

  def get_name
    "#{self.school.code} | #{self.period.name}" if (self.school and self.period)
  end


  def total_enroll_academic_processes
    self.enroll_academic_processes.count
  end

  def label_total_enrolls_by_status
    total = []
    EnrollAcademicProcess.enroll_statuses.map do |k,v|
      total_aux = self.enroll_academic_processes.where(enroll_status: v).count 
      value = v
      total << ApplicationController.helpers.label_status_with_tooptip('bg-secondary', total_aux, k.titleize)
    end
    return total
  end

  def label_total_sections
    total = []
    total << ApplicationController.helpers.label_status_with_tooptip('bg-info', total_sections, 'Total')
    total << ApplicationController.helpers.label_status_with_tooptip('bg-success', total_sections_qualified, 'Calificadas')
    
    total << ApplicationController.helpers.label_status_with_tooptip('bg-danger', total_sections_without_teacher_assigned, 'Sin Profesor Asignado')

    return total
  end

  def total_academic_records
    self.academic_records.count
  end

  def total_sections
    self.sections.count
  end

  def total_sections_qualified
    self.sections.qualified.count
  end

  def total_sections_without_teacher_assigned
    self.sections.without_teacher_assigned.count
  end

  def enrolling?
    self.id.eql? self.school.enroll_process_id
  end

  def readys_to_enrollment_day
    # if process_before
    #   grades_before_ids = self.process_before.grades.ids
    #   grades_ids = self.grades.ids
    #   self.school.grades.without_appointment_time.joins(:academic_processes).where("academic_processes.id IN (?)", grades_before_ids).sort_by_numbers.uniq if process_before
    # end
    self.school.grades.without_appointment_time.enrolled_in_academic_process(self.process_before.id).sort_by_numbers.uniq if process_before
    
  end

  rails_admin do
    navigation_label 'Config Específica'
    navigation_icon 'fa-solid fa-calendar'
    weight -3
    list do
      sort_by 'periods.name'

      field :school do
        column_width 150

        pretty_value do
          value.short_name
        end        
        
      end
      fields :period do
        label 'Período'
        column_width 100
        pretty_value do
          value.name
        end
      end

      field :process_before do
        column_width 100
        pretty_value do
          value.period.name if value
        end
      end

      # field :active_enroll do
      #   pretty_value do
      #     current_user = bindings[:view]._current_user
      #     admin = current_user.admin
      #     active = admin and admin.authorized_manage? 'School'

      #     if active
      #       bindings[:view].render(partial: "/schools/form_enabled_enroll", locals: {academic_process: bindings[:object]})
      #     else
      #       value
      #     end
      #   end
      # end


      field :total_sections do

        column_width 100
        label 'Secciones'
        pretty_value do 
          user = bindings[:view]._current_user
          if (user and user.admin and user.admin.authorized_read? 'Section')
            %{<a href='/admin/section?query=#{bindings[:object].period.name}' title='Total Secciones'><span class='badge bg-info'>#{value}</span></a>}.html_safe
          else
            %{<span class='badge bg-info'>#{value}</span>}.html_safe
          end
        end
      end

      field :total_enroll_academic_processes do
        column_width 100
        label 'Estudiantes'
        pretty_value do
          user = bindings[:view]._current_user
          if (user and user.admin and user.admin.authorized_read? 'EnrollAcademicProcess')
            %{<a href='/admin/enroll_academic_process?query=#{bindings[:object].period.name}' title='Total Estudiantes Inscritos'><span class='badge bg-info'>#{value}</span></a>}.html_safe
          else
            %{<span class='badge bg-info'>#{value}</span>}.html_safe
          end
        end
      end
      field :total_academic_records do
        column_width 100
        label 'Asignaturas'
        pretty_value do
          user = bindings[:view]._current_user
          if (user and user.admin and user.admin.authorized_read? 'AcademicRecord')          
            %{<a href='/admin/academic_record?query=#{bindings[:object].period.name}' title='Totas Asignaturas Inscritas'><span class='badge bg-info'>#{value}</span></a>}.html_safe
          else
            %{<span class='badge bg-info'>#{value}</span>}.html_safe
          end
        end
      end      
    end

    edit do
      # group :default do
      #   hide
      # end      
      field :period do
        inline_edit false
      end
      field :school do
        hide
        inline_edit false
        inline_add false
      end
      field :modality
      field :process_before do
        inline_edit false
        inline_add false
        help 'Atención: Aún cuando este campo no es obligatorio y puede ser omitido (en caso de que se encuentre realizando migraciones de periodos anteriores) es muy importante para las Citas Horarias e Inscripciones'
        pretty_value do
          bindings[:object].period_name
        end
      end

      field :max_credits do
        label 'Máximo de créditos permitidos a inscribir'
      end
      field :max_subjects do
        label 'Máximo de asignaturas permitidas a inscribir'
      end

      field :enroll_instructions do
        help 'Si desea agregar imágenes tome en cuenta el tamaño de misma y su ajuste a la pantalla dónde se desplegará'
      end
    end

    show do
      field :name do
        label 'Descripción'
        pretty_value do
          bindings[:view].render(partial: "/academic_processes/desc_table", locals: {academic_process: bindings[:object]})
        end
      end
      field :enroll_instructions

      # field :courses do
      #   visible do
      #     user = bindings[:view]._current_user
      #     (user and user.admin and user.admin.authorized_manage? 'AcademicProcess')
      #   end
      #   label "Programación"
      #   pretty_value do
      #     bindings[:view].render(partial: "/academic_processes/programation", locals: {academic_process: bindings[:object]})
      #   end
      # end

      # field :enrollment_days do
      #   visible do
      #     user = bindings[:view]._current_user
      #     (user and user.admin and user.admin.authorized_manage? 'AcademicProcess')
      #   end
      #   pretty_value do
      #     if bindings[:object].process_before
      #       enrollment_days = bindings[:object].enrollment_days
      #       grades_without_appointment = bindings[:object].readys_to_enrollment_day

      #       bindings[:view].render(partial: "/enrollment_days/index", locals: {enrollment_days: enrollment_days, grades_without_appointment: grades_without_appointment, academic_process: bindings[:object]})

      #     else
      #       bindings[:view].content_tag(:p, 'Sin proceso academico anterio vinculado. Para habilitar el sistema de Cita Horaria en este proceso académico, por favor edítelo y agregue un proceso anteriór', {class: 'alert alert-warning'})
      #     end
      #   end

      # end
    end

    export do
      fields :school, :period, :modality, :subjects, :max_credits, :max_subjects
    end
  end

  after_initialize do
    if new_record?
      self.school_id ||= School.first.id
    end
  end

  private

    def set_name
      self.name = self.get_name
    end

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
      self.paper_trail_event = "¡Proceso Académico eliminado!"
    end


end
