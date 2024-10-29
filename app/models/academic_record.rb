class AcademicRecord < ApplicationRecord
  # SCHEMA:
  # t.bigint "section_id", null: false
  # t.bigint "enroll_academic_process_id", null: false
  # t.integer "status"

  # ENUMERIZE:
  enum status: {sin_calificar: 0, aprobado: 1, aplazado: 2, retirado: 3, perdida_por_inasistencia: 4}

  # enum special_condition: {pi: 0, equivalencia_interna: 1, equivalencia_externa: 2}

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update


  # ASSOCIATIONS:
  belongs_to :section
  belongs_to :enroll_academic_process

  has_many :qualifications, dependent: :destroy
  accepts_nested_attributes_for :qualifications, allow_destroy: true#, reject_if: proc { |attributes| attributes['academic_record_id'].blank? }  

  has_one :academic_process, through: :enroll_academic_process
  has_one :grade, through: :enroll_academic_process
  has_one :study_plan, through: :grade
  has_one :school, through: :study_plan
  has_one :student, through: :grade
  has_one :address, through: :student
  has_one :user, through: :student
  has_one :period, through: :academic_process
  has_one :period_type, through: :period
  has_one :course, through: :section
  has_one :teacher, through: :section
  has_one :subject, through: :course
  has_one :area, through: :subject

  # VALIDATIONS:
  validates :section, presence: true
  validates :enroll_academic_process, presence: true
  validates :status, presence: true
  validates_uniqueness_of :enroll_academic_process, scope: [:section], message: 'Ya inscrito en la sección', field_name: false

  validates_with SamePeriodValidator, field_name: false  
  validates_with SameSchoolValidator, field_name: false
  validates_with SameSubjectInPeriodValidator, field_name: false, if: :new_record?
  validates_with ApprovedAndEnrollingValidator, field_name: false

  # validates :qualifications, presence: true, if: lambda{ |object| (object.subject.present? and object.subject.numerica? and (object.aprobado? or object.aplazado? or object.equivalencia? ))}

  # OJO: Se usó este validador en luegar del de arriba para poder espeficificar el mensaje
  validates_presence_of :qualifications, message: "Calificación no puede estar en blanco. Si desea eliminar la calificación, coloque el estado de calificación a 'Sin Calificar'", if: lambda{ |object| (object.subject.present? and object.subject.numerica? and (object.aprobado? or object.aplazado?))}

  # CALLBACK
  before_save :set_status_by_EQ_modality_section
  after_save :update_status_q_and_grades
  # after_save :update_grade_numbers#, if: :will_save_change_to_status?

  after_destroy :destroy_enroll_academic_process

  # SCOPE:
  # default_scope { joins(:user, :course, :section, :period, :subject) }
  scope :custom_search, -> (keyword) {joins(:user, :course, :section, :period, :subject).where("users.ci ILIKE '%#{keyword}%' OR users.first_name ILIKE '%#{keyword}%' OR users.last_name ILIKE '%#{keyword}%' OR subjects.name ILIKE '%#{keyword}%' OR subjects.code ILIKE '%#{keyword}%' OR sections.code ILIKE '%#{keyword}%' OR periods.name ILIKE '%#{keyword}%'") }


  scope :prenroll, -> {joins(:enroll_academic_process).where('enroll_academic_processes.enroll_status = ?', :preinscrito)}

  scope :confirmed, -> {joins(:enroll_academic_process).where('enroll_academic_processes.enroll_status = ?', :confirmado)}

  scope :with_totals, ->(school_id, period_id) {joins(:school).where("schools.id = ?", school_id).of_period(period_id).joins(:user).joins(:subject).joins(grade: :study_plan).group(:grade_id).select('study_plans.id plan_id, study_plans.total_credits plan_creditos, grados.*, SUM(subjects.unit_credits) total_creditos, COUNT(*) subjects, SUM(IF (academic_records.status = 1, subjects.creditos, 0)) aprobados')}

  scope :of_period, -> (period_id) {joins(:academic_process).where "academic_processes.period_id = ?", period_id}
  scope :of_periods, lambda { |periods_ids| joins(:academic_process).where "academic_process.period_id IN (?)", periods_ids}
  
  scope :of_academic_process, -> (academic_process_id) {joins(:academic_process).where "academic_processes.id IN (?)", academic_process_id}

  scope :on_reparacion, -> {joins(:qualifications).where('qualificactions.type_q': :reparacion)}

  scope :of_school, lambda {|school_id| includes(:school).where("schools.id = ?", school_id).references(:schools)}
  scope :of_schools, lambda {|schools_ids| includes(:school).where("schools.id IN (?)", schools_ids).references(:schools)}

  scope :of_student, lambda {|student_id| where("student_id = ?", student_id)}

  scope :no_retirados, -> {not_retirado}

  scope :coursed, -> {where "academic_records.status = 1 or academic_records.status = 2 or academic_records.status = 4"}

  scope :qualified, -> {not_sin_calificar}

  scope :by_level, -> (level) {joins(:subject).where('subjects.ordinal': level)}

  scope :coursing, -> {where "academic_records.status != 1 and academic_records.status != 2 and academic_records.status != 3"} # Excluye retiradas también

  scope :total_credits_coursed_on_process, -> (periods_ids) {coursed.joins(:academic_process).where('academic_processes.id': periods_ids).joins(:subject).sum('subjects.unit_credits')}
  scope :total_credits_approved_on_process, -> (periods_ids) {aprobado.joins(:academic_process).where('academic_processes.id': periods_ids).joins(:subject).sum('subjects.unit_credits')}

  scope :total_credits_coursed_on_periods, lambda{|periods_ids| coursed.joins(:academic_process).where('academic_processes.period_id IN (?)', periods_ids).joins(:subject).sum('subjects.unit_credits')}

  scope :total_credits_approved_on_periods, lambda{|periods_ids| aprobado.joins(:academic_process).where('academic_processes.period_id IN (?)', periods_ids).joins(:subject).sum('subjects.unit_credits')}

  scope :total_credits, -> {joins(:subject).sum('subjects.unit_credits')}
  scope :total_credits_by_level, -> (level){by_level(level).sum('subjects.unit_credits')}
  scope :total_subjects, -> {(joins(:subject).group('subjects.id').count).count}

  scope :total_subjects_coursed, -> {coursed.total_subjects}
  scope :section_not_equivalencias, -> {joins(:section).where('sections.modality': [:nota_final, :suficiencia])}
  scope :section_equivalencias, -> {joins(:section).where('sections.modality': [:equivalencia_externa, :equivalencia_interna])}
  scope :total_subjects_approved_by_level, -> (level){aprobado.by_level(level).total_subjects}
  scope :total_subjects_approved_by_level_and_type, -> (level, tipo){aprobado.by_level(level).by_subject_types(tipo).total_subjects}
  scope :total_subjects_equivalence, -> {section_equivalencias.total_subjects}
  
  scope :total_subjects_approved, -> {aprobado.total_subjects}
  scope :total_subjects_approved_equivalence, -> {section_equivalencias.total_subjects_approved}
  scope :total_subjects_approved_not_equivalence, -> {section_not_equivalencias.total_subjects_approved}
  
  scope :total_credits_approved, -> {aprobado.total_credits}
  scope :total_credits_approved_equivalence, -> {section_equivalencias.total_credits_approved}
  scope :total_credits_approved_not_equivalence, -> {section_not_equivalencias.total_credits_approved}  

  scope :total_credits_coursed, -> {coursed.total_credits}
  scope :total_credits_approved_by_level, -> (level) {aprobado.total_credits_by_level(level)}
  scope :total_credits_approved_by_level_and_type, -> (level, tipo) {aprobado.by_level(level).by_subject_types(tipo).total_credits}
  scope :total_credits_equivalence, -> {section_equivalencias.total_credits}
  
  scope :weighted_average, -> {joins(:subject).joins(:qualifications).definitives.coursed.sum('subjects.unit_credits * qualifications.value')}

  scope :definitives, -> {joins(:qualifications).where('qualifications.definitive': true)}

  scope :promedio, -> {joins(:qualifications).coursed.definitives.average('qualifications.value')}
  scope :promedio_approved, -> {aprobado.promedio}
  scope :weighted_average_approved, -> {aprobado.weighted_average}

  scope :student_enrolled_by_period, lambda { |period_id| joins(:academic_process).where("academic_processes.period_id": period_id).group(:student).count } 

  scope :total_by_qualification_modality?, -> {joins(:subject).group("subjects.modality").count}

  scope :students_enrolled, -> { group(:student_id).count } 

  scope :student_enrolled_by_credits, -> { joins(:subject).group(:student_id).sum('subject.unit_credits')} 

  # Esta función retorna la misma cuenta agrupadas por creditos de asignaturas
  scope :student_enrolled_by_credits2, -> { joins(:subject).group('academic_records.student_id', 'subjects.unit_credits').count} 

  scope :sort_by_subject_code, -> {joins(:subject).order('subjects.code': :asc)}
  scope :sort_by_subject_name, -> {joins(:subject).order('subjects.name': :asc)}


  scope :by_subject_types, -> (tipo){joins(:subject).where('subjects.modality': tipo.downcase)}
  # scope :perdidos, -> {perdida_por_inasistencia}

  scope :sort_by_user_name, -> {joins(:user).order('users.last_name asc, users.first_name asc')}


  # FUNCTIONS:
  def values_for_report
    user_aux = user
    [user_aux.ci, user_aux.first_name, user_aux.last_name, school.name, area.name, subject.code, subject.name, subject.unit_credits, self.final_q_to_02i, self.q_value_to_02i, self.tipo_examen, period_type.code, period.year, section.code, study_plan&.code]
  end

  def student_name_with_retired
    aux = user.reverse_name
    aux += " (retirado)" if retirado? 
    return aux
  end


  def data_to_excel

    data = [self.user.ci, self.student_name_with_retired]

    if self.enroll_academic_process
      data << self.enroll_academic_process.enroll_status.titleize if self.enroll_academic_process.enroll_status

      if self.retirado?
        data += ['--', '--']
      else
        data += [self.user.email, self.user.number_phone]
      end
    else
      data += ['--', '--', '--']
    end
    return data
  end

  def get_value_by_status
    if absolute? or pi? or rt? or sin_calificar? or self.section&.any_equivalencia?
      desc_conv_absolute
    else
      "#{self.q_value_to_02i}"
    end
  end

  def set_status valor
    valor.strip!
    valor.upcase!

    if (valor.eql? 'EQ' or valor.eql? 'EE' or valor.eql? 'EI')
      self.status = I18n.t('A')
      self.section.update!(modality: I18n.t(valor))
    elsif (valor.eql? 'NP' or valor.eql? 'PI' or valor.eql? 'RT' or valor.eql? 'A' or valor.eql? 'AP')
      self.status = I18n.t(valor)
      if valor.eql? 'PI' or (valor.eql? 'AP' and subject.numerica?)
        qua = self.qualifications.find_or_initialize_by(type_q: :final)
        qua.value = 0
        return qua.save
      else
        return true
      end
    else
      qua = self.qualifications.find_or_initialize_by(type_q: :final)
      qua.value = valor.to_i
      return qua.save
    end
    return false
  end

  def student_name_with_retiro
    aux = "#{user.reverse_name}"
    aux += " <div class='badge bg-danger'>Retirada</div>" if retirado? 
    return aux
  end

  def subject_name_with_retiro  
    aux = "#{subject.name}"
    aux += " <b>(Retirada)</b>" if retirado? 
    return aux
  end

  def badge_approved
    "<span class= 'badge bg-success'>Aprobado (#{self.q_value_to_02i_to_from})</span>" if self.aprobado?
  end

  def badge_status
    "<span class= 'badge bg-#{self.badge_status_class}'> #{self.status&.titleize} </span>"
  end

  def badge_status_class
    valor = 'secondary'
    valor = 'success' if self.aprobado?
    valor = 'danger' if (self.aplazado? || self.retirado? || self.pi?)
    # valor += ' text-muted' if self.retirado?
    return valor    
  end

  def tr_class_by_status_q
    valor = ''
    valor = 'table-success' if self.aprobado?
    valor = 'table-danger' if (self.aplazado? || self.retirado? || self.pi?)
    valor += ' text-muted' if self.retirado?
    return valor
  end

  def name
    "#{user.ci_fullname} en #{section.name}" if (user and section)
  end

  def absolute?
    subject&.absoluta?
  end

  def absolute_pi_or_rt?
    (absolute? or pi? or rt?)
  end

  def cal_alfa
    value = absolute_pi_or_rt? ? self.status : qualifications.first.type_q
    I18n.t(value)
  end

  def rt?
    retirado?
  end

  def desc_conv
    I18n.t(self.status)
  end

  def desc_conv_absolute
    self.section&.any_equivalencia? ? self.section&.conv_initial_type : I18n.t(self.status)
  end

  def pi?
    perdida_por_inasistencia?
  end

  def preinscrito_in_process?
    self.enroll_academic_process and self.enroll_academic_process.preinscrito?
  end

  def post_q?
    !post_q.nil?
  end

  def diferido?
    (post_q and post_q.diferido?) ? true : false
  end

  def reparacion?
    (post_q and post_q.reparacion?) ? true : false
  end

  def definitive_q
    aux = post_q
    aux ? aux : final_q
  end

  def definitive_q_value
    definitive_q ? definitive_q.value : nil
  end  

  def final_q
    aux = qualification_by :final
    aux ? aux : nil
  end

  def post_q
    aux = qualification_by [:diferido, :reparacion]
    aux ? aux : nil
  end

  def qualification_by type_q
    self.qualifications.by_type_q(type_q).first
  end

  def definitive_label
    definitive_q ? q_value_to_02i : I18n.t(self.status)
  end

  def type_q_label
    if subject.absoluta?
      'Absoluta'
    else
      definitive_q ? definitive_q.type_q.titleize : 'Final' 
    end
  end

  def tipo_examen
    aux = qualifications.definitive.first
    aux.nil? ? 'F' : aux.desc_conv.last
  end
  def final_q_to_02i
    q_value_to_02i final_q
  end

  def final_q_to_02i_to_from
    q_value_to_02i_to_from final_q
  end

  def final_type_q
    final_q ? final_q.type_q : nil
  end

  def final_q_value 
    q_value final_q
  end

  def post_q_value 
    q_value post_q
  end

  def q_value qualification=definitive_q
    qualification ? qualification.value : nil
  end

  def post_type_q
    post_q ? post_q.type_q : nil
  end

  def post_q_to_02i
    q_value_to_02i post_q
  end

  def definitive_type_q
    definitive_q ? definitive_q.type_q : :final
  end

  def q_value_to_02i_to_from qualification=definitive_q
    qualification ? qualification.value_to_02i : nil
  end
  def q_value_to_02i qualification=definitive_q
    if qualification
      qualification.value_to_02i
    elsif self.section&.any_equivalencia?
      self.section&.conv_initial_type
    else 
      '--'
    end
  end

  def description_q force_final = false
    qualification = force_final ? final_q : definitive_q
    qualification ? (num_to_s qualification) : self.status.to_s.humanize.upcase 
  end

  def num_to_s num = definitive_q_value 
    if pi?
      'CERO'
    elsif retirado? or (subject and subject.absoluta?) or num.nil? or !(num.is_a? Integer or num.is_a? Float)
      status&.humanize&.upcase
    else
      numeros = %W(CERO UNO DOS TRES CUATRO CINCO SEIS SIETE OCHO NUEVE DIEZ ONCE DOCE TRECE CATORCE QUINCE DIECISÉIS DIECISIETE DIECIOCHO DIE)
      # dieciséis, diecisiete, dieciocho y diecinueve
      num = num.to_i
        
      if num < 10 
        "#{numeros[0]} #{numeros[num]}"
      elsif num >= 10  and num < 16
        numeros[num]
      elsif num >= 16 and num < 20
        aux = num % 10
        "#{numeros[10]} Y #{numeros[aux]}"
      elsif num == 20
        'VEINTE'
      else
        'INVÁLIDA'
      end
    end
  end


  def conv_type
    type = definitive_type_q[0]
    type ||= 'F'

    modality_process = academic_process.modality[0]
    modality_process ||= 'A'

    "#{type.upcase}#{modality_process.upcase}#{period.period_type.code.last}"
  end  

  def conv_descrip force_final = false # convocados

    data = [self.user.ci, self.user.reverse_name, self.study_plan.code]

    if force_final
      data << I18n.t('aplazado')
      data << I18n.t('final')
      data << self.q_value_to_02i(final_q)
      data << self.description_q(true)
    else
      data << I18n.t(self.status)
      data << I18n.t(self.definitive_type_q)
      data << self.q_value_to_02i #unless self.subject.as_absolute?
      data << self.description_q
    end

    return data

  end

  def self.update_academic_records_with_equivalence
    AcademicRecord.equivalencia.each do |ar| 
      coruse_aux = ar.course
      section_eq = coruse_aux.sections.where(modality: :equivalencia_externa).first
      section_eq ||= coruse_aux.sections.create(code: 'EE', modality: :equivalencia_externa, capacity: 10) 

      ar.update!(section_id: section_eq.id)
    end
  end

  # RAILS_ADMIN
  rails_admin do
    navigation_label 'Reportes'
    navigation_icon 'fa-solid fa-signature'
    weight 1
    # visible false

    list do
      search_by :custom_search
      sort_by 'periods.name'
      # filters [:period_name, :section_code, :subject_code, :student_desc]

      # field :period_name do
      #   label 'Período'
      #   column_width 100
      #   # searchable 'periods_academic_records.name'
      #   # filterable 'periods_academic_records.name'
      #   # sortable 'periods_academic_records.name'
      #   formatted_value do
      #     bindings[:object].period.name if bindings[:object].period
      #   end
      # end

      field :period do
        label 'Periodo'
        column_width 120

        associated_collection_cache_all false
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          Proc.new { |scope|
            # scoping all Players currently, let's limit them to the team's league
            # Be sure to limit if there are a lot of Players and order them by position
            scope = scope.joins(:period)
            scope = scope.limit(30) # 'order' does not work here
          }
        end

        searchable :name
        # filterable :name
        sortable :name
        pretty_value do
          value.name
        end
      end

      field :area do
        searchable :name
        sortable :name
      end

      field :section_code do
        label 'Sec'
        column_width 50
        # searchable 'sections.code'
        # filterable 'sections.code'
        # sortable 'sections.code'
        formatted_value do
          bindings[:view].link_to(bindings[:object].section.code, "/admin/section/#{bindings[:object].section_id}") if bindings[:object].section.present?
        end
      end

      # field :subject_code do
      #   label 'Asignatura'
      #   column_width 300
      #   # searchable ['subjects_academic_records.code', 'subjects_academic_records.name']
      #   # filterable ['subjects_academic_records.code', 'subjects_academic_records.name']
      #   # sortable 'subjects_academic_records.code'
      #   formatted_value do
      #     bindings[:view].link_to( bindings[:object].subject.desc, "/admin/subject/#{bindings[:object].subject.id}") if bindings[:object].subject.present?
      #   end
      # end

      field :subject do
        label 'Asignatura'
        column_width 300

        searchable 'subjects.code'
        filterable false
        sortable 'subjects.code'

        associated_collection_cache_all false
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          Proc.new { |scope|
            # scoping all Players currently, let's limit them to the team's league
            # Be sure to limit if there are a lot of Players and order them by position
            scope = scope.joins(:subject, :course)
            scope = scope.limit(30) # 'order' does not work here
          }
        end
      end      

      field :student_desc do
        label 'Estudiante'
        column_width 240
        # searchable ['users.ci', 'users.first_name', 'users.last_name']
        # filterable ['users.ci', 'users.first_name', 'users.last_name']
        # sortable 'users.ci'
        formatted_value do
          bindings[:view].link_to(bindings[:object].student.name, "/admin/student/#{bindings[:object].student.id}") if bindings[:object].student.present?
        end
      end

      field :credits do
        label 'Creditos'
        column_width 30
        formatted_value do
          bindings[:object].subject.unit_credits if bindings[:object].subject
        end        
      end
      
      field :definitive_label do
        label 'Definitiva'
        column_width 30
      end
      field :status do
        label 'Estado'
        column_width 200
        pretty_value do
          ApplicationController.helpers.label_status('bg-info', value.titleize)
        end        
      end
    end

    update do
      field :period do
        pretty_value do
          bindings[:view].content_tag(:b, bindings[:object].period.name)
        end
        read_only true
      end 
      field :subject do
        pretty_value do
          bindings[:view].content_tag(:b, bindings[:object].subject.name)
        end

        read_only true
      end

      field :section do
        label 'Sección'
        pretty_value do
          bindings[:view].content_tag(:b, bindings[:object].section.code)
        end
        read_only true
      end 

      field :status do
        visible do
          user = bindings[:view]._current_user
          (user and user.admin and user.admin.authorized_manage? 'Qualification')
        end
      end
      field :qualifications do
        visible do
          user = bindings[:view]._current_user
          (user and user.admin and user.admin.authorized_manage? 'Qualification')
        end
      end
    end

    edit do
      field :section do
        inline_edit false
        help 'Ingrese el código de la asignatura y SELECCIONE la sección correspondiente al período requerido'
      end

      field :enroll_academic_process do 
        # inline_add false
        inline_edit false
        help 'Ingrese la cédula de identidad del estudiante y SELECCIONE la inscripción correspondiente al período'
      end
      field :status do
        visible do
          user = bindings[:view]._current_user
          (user and user.admin and user.admin.authorized_manage? 'Qualification')
        end
      end
      field :qualifications do
        visible do
          user = bindings[:view]._current_user
          (user and user.admin and user.admin.authorized_manage? 'Qualification')
        end
      end
    end

    show do
      
    end

    export do
      fields :section, :enroll_academic_process

      field :qualifications do
      end
      field :period do
        label 'Período'
        searchable :name
        sortable :name
      end

      field :area do
        label 'Área'
        searchable :name
        sortable :name
      end

      field :study_plan do
      end

      # field :period do
      #   label 'Periodo'
      #   column_width 120

      #   associated_collection_cache_all false
      #   associated_collection_scope do
      #     # bindings[:object] & bindings[:controller] are available, but not in scope's block!
      #     Proc.new { |scope|
      #       # scoping all Players currently, let's limit them to the team's league
      #       # Be sure to limit if there are a lot of Players and order them by position
      #       scope = scope.joins(:period)
      #       scope = scope.limit(30) # 'order' does not work here
      #     }
      #   end
      # end

      field :get_value_by_status, :string do
        label 'Calificación Definitiva'
      end
      fields :status, :qualifications, :period_type, :student, :user, :address, :subject
    end
  end  

  private

  def self.import row, fields

    total_newed = total_updated = 0
    no_registred = nil

    # BUSCAR PERIODO
    if row[3]
      row[3] = row[3].to_s
      row[3].strip!
      row[3].upcase!
    end

    row[3] = fields[:nombre_periodo] if row[3].blank?

    # ENCONTRAR O CREAR PERIODO
    if row[3]
      year, type = row[3].split('-')
      period_type = PeriodType.find_by_code(type[0..1])
      modality = type[2]
      period = Period.find_or_create_by(year: year, period_type_id: period_type.id)
    end

    if period
      # LIMPIAR CI
      if row[0]
        row[0] = row[0].to_s
        row[0].strip!
        row[0].delete! '^0-9'
      else
        return [0,0,0]
      end

      # LIMPIAR CODIGO ASIGNATURA
      if row[1]
        row[1] = row[1].to_s
        row[1].strip!
      else
        return [0,0,'1b']
      end

      subject = Subject.find_by(code: row[1])
      subject ||= Subject.find_by(code: "0#{row[1]}")

      if !subject.nil?
        # p "     SUBJECT: #{subject.name}    ".center(300, "U")
        study_plan = StudyPlan.find fields[:study_plan_id]
        if !study_plan.nil?
          # p "     STUDY PLAN: #{study_plan.name}    ".center(300, "P")

          escuela = study_plan.school
          
          # BUSCAR O CREAR PROCESO ACADEMICO:
          case modality
          when 'S'
            modality = :Semestral
          when 'I'
            modality = :Intensivo
          else
            modality = :Anual
          end
          
          academic_process = AcademicProcess.where(period_id: period.id, modality: modality, school_id: escuela.id).first

          if academic_process.nil?
            academic_process = AcademicProcess.create(period_id: period.id, modality: modality, school_id: escuela.id, max_credits: 24, max_subjects: 5)
          end

          # BUSCAR O CREAR EL CURSOS (PROGRAMACIÓN):
          # p "     ACADEMIC PROCESS: #{academic_process.name}    ".center(300, "P")

          if curso = Course.find_or_create_by(subject_id: subject.id, academic_process_id: academic_process.id)

            # BUSCAR O CREAR SECCIÓN
            if row[2]
              row[2] = row[2].to_s
              row[2].strip!
              row[2].upcase!
            else
              return [0,0,2]
            end

            s = Section.where(code: row[2], course_id: curso.id).first
            s ||= Section.where(code: "0#{row[2]}", course_id: curso.id).first
            if s.nil?
              s = Section.new(code: row[2], course_id: curso.id)
              s.set_default_values_by_import
            end

            if s.save
              # p "          SECTION: id:<#{s.id}> #{s.name}         ".center(1000, "S")

              # BUSCAR USUARIO
              user = User.find_by(ci: row[0])
            
              if user and user.student?
                if stu = user.student
                  # p "     STUDENT: #{stu.user_ci}    ".center(300, "E")

                  # BUSCAR O CREAR GRADO
                  grade = Grade.find_by(study_plan_id: study_plan.id, student_id: stu.id)
                  if !grade.nil?
                    # p "     GRADE: #{grade.name}    ".center(300, "G")

                    # BUSCAR O CREAR INSCRIPCIÓN PROCESO ACADEMICO:
                    enroll_academic_process = EnrollAcademicProcess.find_or_initialize_by(academic_process_id: academic_process.id, grade_id: grade.id)

                    enroll_academic_process.set_default_values_by_import if enroll_academic_process.new_record?

                    if enroll_academic_process.save
                      # p "     ENROLL ACADEMIC PROCESS: #{enroll_academic_process.id} #{enroll_academic_process.name} section_id: #{s.id}   ".center(500, "E")
                      # BUSCAR O CREAR REGISTRO ACADEMICO
                      # academic_record = AcademicRecord.find_or_create_by(section_id: s.id, enroll_academic_process_id: enroll_academic_process.id)
                      
                      academic_record = AcademicRecord.where(section_id: s.id, enroll_academic_process_id: enroll_academic_process.id).first
                      if academic_record.nil?
                        academic_record = AcademicRecord.new(section_id: s.id, enroll_academic_process_id: enroll_academic_process.id)
                        if academic_record.save
                          total_newed = 1
                          # p "     NUEVO REGISTRO ACADEMICO: #{academic_record.id}    ROW: #{row[0]} : #{row[1]} : #{row[2]}   ".center(1000, "N")
                        else
                          no_registred = "#{academic_record.errors.full_messages.to_sentence.truncate(15)}"
                        end
                      else
                        total_updated = 1
                        # p "     SIN CAMBIO REGISTRO ACADEMICO: #{academic_record.name}    ".center(1000, "A")
                        
                      end

                      if row[4] and (total_newed.eql? 1 or total_updated.eql? 1)
                        row[4] = row[4].to_s
                        row[4].strip! 
                        calificacion_correcta = academic_record.set_status row[4]
                        unless (calificacion_correcta.eql? true and academic_record.save)
                          no_registred = 'valor nota'
                        end
                      end

                      # if academic_record.save
                      #   p "     EXITO. GUARDADO EL REGISTRO ACADEMICO: #{academic_record.name}    ".center(500, "#")
                      # else
                      #   no_registred = "#{academic_record.errors.full_messages.to_sentence.truncate(15)}"
                      # end
                    else
                      no_registred = 'proceso academico'
                    end
                  else
                    no_registred = 'grado'
                  end
                else
                  no_registred = 'estudiante'
                end

              else
                no_registred = 'error'
              end

            else
              no_registred = 2
            end
          else
            no_registred = 1 
          end

        else
          no_registred = 1 # Study Plan
        end
      else
        no_registred = row[1]
      end
    else
      no_registred = 3
    end
    
    [total_newed, total_updated, no_registred]
  end

  private

  # TRIGGER FUNCTIONS:
  def validate_state_vs_qualification
    if definitive_q and (self.aprobado? or self.aplazado?)
      self.status = definitive_q.approved? ? :aprobado : :aplazado
    end

  end

  def set_status_by_EQ_modality_section
    if self.section&.any_equivalencia?
      self.status = :aprobado
      self.qualifications.destroy_all  
    end
  end

  def update_status_q_and_grades
    set_options_q
    update_grade_numbers
  end

  def set_options_q
    self.qualifications.destroy_all if (self.pi? or self.retirado? or self.sin_calificar? or (self.subject and self.subject.absoluta?))

    self.qualifications.create(type_q: :final, value: 0) if self.pi?
  end

  def destroy_enroll_academic_process
    self.enroll_academic_process.destroy unless self.enroll_academic_process.academic_records.any?
  end

  def update_grade_numbers
    self.grade.update(efficiency: self.grade.calculate_efficiency, simple_average: self.grade.calculate_average, weighted_average: self.grade.calculate_weighted_average)
  end

  def paper_trail_update
    changed_fields = self.changes.keys - ['created_at', 'updated_at']
    object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
    self.paper_trail_event = "¡#{object} actualizado en #{changed_fields.to_sentence}"
  end  

  def paper_trail_create
    object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
    self.paper_trail_event = "¡Completada inscripción en oferta académica!"
  end  

  def paper_trail_destroy
    object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
    self.paper_trail_event = "¡Registro Académico eliminado!"
  end

end
