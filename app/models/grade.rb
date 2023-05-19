class Grade < ApplicationRecord
  # SCHEMA:
  # t.bigint "student_id", null: false
  # t.bigint "study_plan_id", null: false
  # t.integer "graduate_status"
  # t.bigint "admission_type_id", null: false
  # t.integer "registration_status"
  # t.float "efficiency"
  # t.float "weighted_average"
  # t.float "simple_average"
  # t.datetime "appointment_time"
  # t.integer "duration_slot_time"

  # ASSOCIATIONS:
  belongs_to :student, primary_key: :user_id
  belongs_to :study_plan
  belongs_to :admission_type
  belongs_to :enabled_enroll_process, foreign_key: 'enabled_enroll_process_id', class_name: 'AcademicProcess', optional: true

  has_one :school, through: :study_plan
  has_one :user, through: :student
  
  has_many :enroll_academic_processes, dependent: :destroy
  has_many :academic_processes, through: :enroll_academic_processes
  has_many :academic_records, through: :enroll_academic_processes

  has_many :payment_reports, as: :payable, dependent: :destroy

  # ENUMERIZE:
  enum registration_status: [:universidad, :facultad, :escuela]
  enum enrollment_status: [:preinscrito, :asignado, :confirmado]
  enum graduate_status: [:no_graduable, :tesista, :posible_graduando, :graduando, :graduado]


  # VALIDATIONS:
  # validates :student, presence: true
  validates :study_plan, presence: true
  validates :admission_type, presence: true

  validates_uniqueness_of :study_plan, scope: [:student], message: 'El estudiante ya tiene el grado asociado', field_name: false

  #SCOPES:
  scope :with_day_enroll_eql_to, -> (day){ where(appointment_time: day.all_day)}
  scope :with_appointment_time, -> { where("appointment_time IS NOT NULL")}
  scope :with_appointment_time_eql_to, -> (dia){ where("date(appointment_time) = '#{dia}'")}
  scope :without_appointment_time, -> { where(appointment_time: nil)}

  # scope :with_enrollments_in_period, -> (period_id) { joins(academic_records: {section: {course: :academic_process}}).where('(SELECT COUNT(*) FROM academic_records WHERE academic_records.estudiante_id = grades.student_id) > 0 and secciones.periodo_id = ?', periodo_id) }

  # scope :with_enrollments_in_period, -> (period_id) { joins(academic_records: {section: {course: :academic_process}}).where('(SELECT COUNT(*) FROM academic_records WHERE academic_records.enroll_academic_process_id = enroll_academic_processes.id) > 0 and academic_processes.period_id = ?', period_id) }

  # scope :with_enrollments_in_period, -> (period_id) { joins(academic_records: {section: {course: :academic_process}}).where('academic_processes.period_id = ?', period_id).group(:'enroll_academic_processes.id').having('COUNT(*) > 0').count}

  # ATENCIÓN: EL UNIQ DEBO HACERLO EN EL LLAMADO DEL SCOPE ANTERIOR YA QUE DE LO CONTRARIO DEVUELVE LA CANTIDAD DE REGISTROS VINCULADOS A LAS enroll_academic_processes

  scope :enrolled_in_academic_process, -> (academic_process_id) { joins(:enroll_academic_processes).where('enroll_academic_processes.academic_process_id': academic_process_id) }

  # scope :not_enrolled_in_academic_process, -> (academic_process_id) { joins(:enroll_academic_processes, :academic_processes).where.not("academic_processes.id": academic_process_id) }

  scope :not_enrolled_in_academic_process, -> (academic_process_id) {joins(:enroll_academic_processes).where('enroll_academic_processes.academic_process_id != ?', academic_process_id)}

  scope :left_not_enrolled_in_academic_process, -> (academic_process_id) {left_joins(:enroll_academic_processes).where('enroll_academic_processes.academic_process_id != ?', academic_process_id)}


  scope :sort_by_numbers, -> () {order([efficiency: :desc, simple_average: :desc, weighted_average: :desc])}
  
  scope :total_with_enrollments_in_period, -> (period_id) { with_enrollments_in_period(period_id).uniq.count }

  # scope :with_academic_records, -> { where('(SELECT COUNT(*) FROM  "grades" INNER JOIN "enroll_academic_processes" ON "enroll_academic_processes"."grade_id" = "grades"."id" INNER JOIN "academic_records" ON "academic_records"."enroll_academic_process_id" = "enroll_academic_processes"."id") > 0') }

  scope :with_academic_records, -> {joins(:academic_records)}
  
  scope :without_academic_records, -> { where('(SELECT COUNT(*) FROM  "grades" INNER JOIN "enroll_academic_processes" ON "enroll_academic_processes"."grade_id" = "grades"."id" INNER JOIN "academic_records" ON "academic_records"."enroll_academic_process_id" = "enroll_academic_processes"."id") IS NULL') }

  scope :without_enroll_academic_processes, -> {left_joins(:enroll_academic_processes).where('enroll_academic_processes.grade_id': nil)}

  # AVANCES EN PIGGLY-SCOPE
  # scope :without_enroll_in_academic_processes, -> (academic_process_id) {left_joins(:enroll_academic_processes).where('enroll_academic_processes.grade_id': nil, 'enroll_academic_processes.academic_process_id': academic_process_id)}

  scope :custom_search, -> (keyword) { joins(:user, :school).where("users.ci ILIKE '%#{keyword}%' OR schools.name ILIKE '%#{keyword}%'") }

  # FUNCTIONS:
  # APPOINTMENT_TIME:
  def appointment_slot_time
    (self.appointment_time and self.duration_slot_time) ? self.appointment_time+self.duration_slot_time.minutes : nil    
  end

  def appointment_from_to
    if self.appointment_time and self.appointment_slot_time
      aux = (I18n.localize(self.appointment_time, format: "%A, %d de %B de %Y de %I:%M%p")) 
      aux += (I18n.localize(self.appointment_slot_time, format: "a %I:%M%p,"))
      return aux
    end
  end

  def appointment_from
    I18n.l(self.appointment_time, format: "%I:%M %p") if self.appointment_time
  end

  def appointment_to
    I18n.l(self.appointment_time+self.duration_slot_time.minutes, format: "%I:%M %p") if (self.appointment_time and self.duration_slot_time.minutes)
  end

  def appointment_time_desc
    if (appointment_time and duration_slot_time)
      aux = ""
      aux += "#{I18n.l(appointment_time)}" if appointment_time
      aux += " | duración: #{duration_slot_time} minutos" if duration_slot_time
      return aux
    end
  end

  def label_status_enroll_academic_process(academic_process_id)
    if iep = self.enroll_academic_processes.of_academic_process(academic_process_id).first
      iep.label_status
    else
      ApplicationController.helpers.label_status('bg-secondary', 'Sin Inscripción')
    end
  end

  def subjects_offer_by_dependent
    # Buscamos los ids de las asignaturas aprobadas

    if is_new?
      Subject.independents.where(ordinal: 1)
    else
      aprobadas_ids = self.subjects_approved_ids

      # Buscamos por ids de las asignaturas que dependen de las aprobadas
      dependent_subject_ids = SubjectLink.in_prelation(aprobadas_ids).not_in_dependency(aprobadas_ids).pluck(:depend_subject_id).uniq

      # ids_subjects_positives = []

      # Ahora por cada asignatura válida miramos sus respectivas dependencias a ver si todas están aprobadas

      # OJO: REVISAR, Creo que este paso es REDUNDANTE, si tienes las dependencias de las aprovadas, no deberías mirar si aprobó las asignaturas de esas dependencias. 
      # dependent_subject_ids.each do |subj_id|
      #   ids_aux = SubjectLink.where(depend_subject_id: subj_id).map{|dep| dep.prelate_subject_id}
      #   ids_aux.reject!{|id| aprobadas_ids.include? id}
      #   ids_subjects_positives << subj_id if (ids_aux.eql? []) #Si aprobó todas las dependencias
      # end

      # Buscamos las asignaturas sin prelación
      ids_subjects_independients = self.school.subjects.independents.not_inicial.ids

      # Sumamos todas las ids ()
      asignaturas_disponibles_ids = dependent_subject_ids + ids_subjects_independients

      Subject.where(id: asignaturas_disponibles_ids)
    end
  end

  def is_new?
    !enroll_academic_processes.any?
  end

  def academic_records_any?
    self.academic_records.any?
  end

  def can_enroll_by_apponintment? #puede_inscribir?
    ((self.appointment_time and self.duration_slot_time) and (Time.zone.now > self.appointment_time) and (Time.zone.now < self.appointment_time+self.duration_slot_time.minutes) ) ? true : false
  end

  def user
    student.user if student
  end

  def name
    "#{study_plan.name}: #{student.name} (#{admission_type.name})" if study_plan and student and admission_type
  end

  def description
    "Plan de Estudio: #{study_plan.name}, Admitido vía: #{admission_type.name}, Estado de Inscripción: #{registration_status.titleize}" if (study_plan and admission_type and registration_status)
  end


  # NUMBERSTINY:

  def numbers
    "Efi: #{efficiency}, Prom. Ponderado: #{weighted_average}, Prom. Simple: #{simple_average}"
    # redear una tabla descripción. OJO Sí es posible estandarizar
  end

  def subjects_approved
    self.academic_records.aprobado.joins(:subject).select('subjects.id')
  end

  def subjects_approved_ids
    subjects_approved.map{|su| su.id}
  end

  # TOTALS CREDITS:

  def credits_completed_by_type tipo
    academic_records.aprobado.or(academic_records.equivalencia).by_subject_types(tipo).total_credits
  end

  def total_credits
    self.academic_records.total_credits
  end

  def total_credits_coursed process_ids = nil
    if process_ids
      academic_records.total_credits_coursed_on_process process_ids
    else
      academic_records.total_credits_coursed
    end
  end

  def total_credits_approved process_ids = nil
    if process_ids
      academic_records.total_credits_approved_on_process process_ids
    else
      academic_records.total_credits_approved
    end
  end

  def total_credits_eq
    self.academic_records.total_credits_equivalence
  end

  def total_credits_approved_or_eq
    academic_records.aprobado.or(academic_records.equivalencia).total_credits
  end

  def total_credits_by_type_subject tipo
    academic_records.joins(:subject).by_type(tipo).total_credits
  end

  # def credits_approved_by_eq
    # Ojo: Esta función siempre arroja cero porque no pueden existir EI y A, porque son estados direrentes

  #   self.academic_records.aprobado.joins(:subject, :section).equivalencia.sum('subjects.unit_credits')
  # end

  # TOTALS SUBJECTS:
  def total_subjects_coursed
    academic_records.total_subjects_coursed
  end

  def total_subjects_approved
    academic_records.total_subjects_approved
  end

  def total_subjects_eq
    academic_records.total_subjects_equivalence
  end  

  def total_subjects_approved_or_eq
    academic_records.aprobado.or(academic_records.equivalencia).total_subjects
  end

  def total_subjects_retiradas
    academic_records.retirado.total_subjects
  end

  def update_all_efficiency

    Grados.each do |gr| 
      academic_records = gr.academic_records
      cursados = academic_records.total_credits_coursed
      aprobados = academic_records.total_credits_approved

      eficiencia = (cursados and cursados > 0) ? (aprobados.to_f/cursados.to_f).round(4) : 0.0

      aux = academic_records.coursed

      promedio_simple = aux ? aux.round(4) : 0.0

      aux = academic_records.weighted_average
      ponderado = (cursados > 0) ? (aux.to_f/cursados.to_f).round(4) : 0.0
    end

  end

  def calculate_efficiency periods_ids = nil 
        cursados = self.total_credits_coursed periods_ids
        aprobados = self.total_credits_approved periods_ids
    (cursados > 0 and aprobados != cursados) ? (aprobados.to_f/cursados.to_f).round(4) : 1.0
  end

  def calculate_average periods_ids = nil
    if periods_ids
      aux = academic_records.of_periods(periods_ids).promedio
    else
      aux = academic_records.promedio
    end

    (aux and aux.is_a? BigDecimal) ? aux.to_f.round(4) : 0.0

  end

  def calculate_weighted_average periods_ids = nil
    if periods_ids
      aux = academic_records.of_periods(periods_ids).weighted_average
    else
      aux = academic_records.weighted_average
    end
    cursados = self.total_credits_coursed periods_ids

    (cursados > 0 and aux) ? (aux.to_f/cursados.to_f).round(4) : 0.0
  end

  def calculate_weighted_average_approved

    aprobados = self.academic_records.total_credits_approved
    aux = self.academic_records.weighted_average_approved
    (aprobados > 0 and aux and aux.is_a? BigDecimal) ? (aux.to_f/aprobados.to_f).round(4) : 0.0
    
  end

  def calculate_average_approved
    aux = self.academic_records.promedio_approved
    (aux and aux.is_a? BigDecimal) ? aux.round(4) : 0.0
  end


  # RAILS_ADMIN:
  rails_admin do
    visible false
    navigation_label 'Inscripciones'
    navigation_icon 'fa-solid fa-graduation-cap'

    list do
      search_by :custom_search
      fields :student, :study_plan, :admission_type, :registration_status, :efficiency, :weighted_average, :simple_average
    end

    show do
      fields :student, :enroll_academic_processes, :enabled_enroll_process
      field :numbers
      field :description
    end

    update do
      fields :study_plan, :admission_type, :registration_status, :enabled_enroll_process, :enrollment_status
      field :appointment_time do
        label 'Fecha y Hora Cita Horaria'
      end
      field :duration_slot_time do 
        label 'Duración Cita Horaria (minutos)'
      end
    end

    edit do
      fields :study_plan, :admission_type, :registration_status
      field :enrollment_status
      field :appointment_time do
        label 'Fecha y Hora Cita Horaria'
      end
      field :duration_slot_time do 
        label 'Duración Cita Horaria (minutos)'
      end      
    end

    export do
      fields :student, :study_plan, :admission_type, :registration_status
    end
  end

  after_initialize do
    if new_record?
      self.study_plan_id ||= StudyPlan.first.id if StudyPlan.first
    end
  end  

end
