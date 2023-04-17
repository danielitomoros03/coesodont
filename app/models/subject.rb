class Subject < ApplicationRecord
  # SCHEMA:
  # t.string "code", null: false
  # t.string "name", null: false
  # t.boolean "active", default: true
  # t.integer "unit_credits", default: 24, null: false
  # t.integer "ordinal", default: 0, null: false
  # t.integer "qualification_type"
  # t.integer "modality"
  # t.bigint "area_id", null: false  
  # t.boolean "force_absolute", default: false  

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  # ASSOCIATIONS:
  belongs_to :area
  has_one :school, through: :area

  has_many :courses, dependent: :destroy
  has_many :sections, through: :courses

  has_many :parents, foreign_key: :subject_dependent_id, class_name: 'Dependency'
  has_many :subject_parents, through: :parents
  # accepts_nested_attributes_for :subject_parents

  has_many :dependencies, foreign_key: :subject_parent_id, class_name: 'Dependency', dependent: :delete_all
  has_many :subject_dependents, through: :dependencies

  # ENUMS:
  enum qualification_type: [:numerica, :absoluta]
  enum modality: [:obligatoria, :electiva, :optativa] 

  # VALIDATIONS:
  validates :code, presence: true, uniqueness: {case_sensitive: false}
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :ordinal, presence: true
  validates :modality, presence: true
  validates :qualification_type, presence: true
  validates :unit_credits, presence: true
  validates :area, presence: true

  # SCOPES: 

  scope :todos, -> {where('0 = 0')}

  scope :custom_search, -> (keyword) {joins([:area]).where("subjects.name ILIKE ? or subjects.code ILIKE ? or areas.name ILIKE ?", "%#{keyword}%", "%#{keyword}%", "%#{keyword}%")} 

  scope :independents, -> {joins('LEFT JOIN dependencies ON dependencies.subject_dependent_id = subjects.id').where('dependencies.subject_dependent_id IS NULL')}

  # CALLBACKS:
  before_save :clean_values
  
  # HOOKS:
  def clean_values
    self.name.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ.() '
    self.name.strip!
    self.code.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ'
    self.code.strip!
    self.name.upcase!
    self.code.upcase!
    self.code = "0#{self.code}" if self.code[0] != '0' 
  end

  # GENERALS FUNCTIONS: 
  # DEPENDENCIES FUNCTIONS:

  def full_dependency_tree_ids
    aux = []
    aux << prelation_tree_ids
    aux << dependency_tree_ids
    return aux.flatten.uniq
  end

  def prelation_tree_ids
    if parents.any?
      parents.map{|dep| [self.id, dep.subject_parent.prelation_tree_ids]}
    else
      self.id
    end
  end

  def dependency_tree_ids
    if dependencies.any?
      dependencies.map{|dep| [self.id, dep.subject_dependent.dependency_tree_ids]}
    else
      self.id
    end
  end

  # DESCRIPTIONS TYPES:

  def desc
    "#{self.code}: #{self.name}"
  end

  def desc_confirm_enroll
    "- #{self.name} - #{self.unit_credits}"
  end

  def description_code
    desc
  end

  def description_id_with_credits
    "#{description_code} (#{unit_credits} Unidades de Créditos)"
  end

  def desc_to_select
    "- #{self.description_code} - #{self.unit_credits}"
  end

  def description_code_with_school
    "#{description_code} <span class='badge badge-success'>#{self.school.code}</span>".html_safe
  end

  def description_complete
    "#{description_code} - #{self.area.name}"
  end

  def as_absolute?
    self.absoluta? or self.force_absolute?
  end

  def conv_header
    data = ["N°", "CÉDULA", "APELLIDOS Y NOMBRES", "PLAN", "CALIF. DESCR.", "TIPO", "CALIF. EN LETRAS"]

    data.insert(6, "CALIF. NUM.") unless self.as_absolute?

    return data

  end

  def label_modality
    return ApplicationController.helpers.label_status("bg-info", self.modality.titleize)

  end

  def modality_initial_letter
    case modality
    when 'obligatoria'
      'B'
    when 'electiva'
      'O'
    when 'optativa'
      'L'
    when 'proyecto'
      'P'
    end      
  end

  def total_dependencies
    self.dependencies.count
  end

  def total_courses
    courses.count
  end

  rails_admin do
    navigation_label 'Gestión Académica'
    navigation_icon 'fa-regular fa-book'
    weight -1

    object_label_method do
      :desc
    end

    list do
      scopes [:todos, :obligatoria, :electiva, :optativa]
      search_by :custom_search

      field :code do
        searchable true
      end

      field :name do
        column_width 300
        searchable true
      end

      field :area do
        column_width 200
        searchable :name
      end
      field :unit_credits do 
        label 'Crédi'
        column_width 20
      end

      field :total_courses do
        label 'Cursos'
        column_width 20
      end

      field :modality_label do
        label 'Modalidad'
        column_width 20
        searchable 'modality'
        filterable 'modality'
        sortable 'modality'
        formatted_value do
          bindings[:object].label_modality
        end        
      end


      field :total_dependencies do
        label 'Depends'
        column_width 20
      end
    end

    show do
      fields :area, :code, :name, :unit_credits, :ordinal, :qualification_type, :modality, :created_at, :updated_at, :subject_parents, :subject_dependents, :courses, :sections
    end

    edit do
      field :area
      field :code do
        html_attributes do
          {length: 20, size: 20, onInput: "$(this).val($(this).val().toUpperCase().replace(/[^A-Za-z0-9]/g,''))"}
        end  
      end
      field :name do
        html_attributes do
          {:onInput => "$(this).val($(this).val().toUpperCase())"}
        end  
      end      
      fields :modality, :unit_credits

      field :ordinal do
        html_attributes do
          {min: 0, max: 20}
        end
        help 'Semestre o año en que se ubica la asignatura'
      end

      field :qualification_type do
        # help 'Parcial3 equivale a asignatura con 3 calificaciones parciales'
      end

      field :subject_parents do
        inline_add false
        inline_edit false
        help 'Asignatura(s) que prela directamente esta Asignatura. El estudiante debe aprobar la(s) asignatura(s) seleccionada(s) a continuación para que esta asignatura sea ofertada.'
      end
      # field :subject_dependents do
      #   inline_add false
      #   inline_edit false
      #   help 'Asignatura(s) que dependen directamente de esta asignatura. Si el estudiante aprueba esta asignatura, la(s) asignatura(s) seleccionada(s) a continuación podrán ser ofertadas.'
      # end
    end

    export do
      fields :code, :name, :area, :unit_credits, :ordinal, :qualification_type, :modality
    end
  end

  private
  
  def self.import row, fields
    total_newed = total_updated = 0
    no_registred = nil
    area = Area.find(fields['area_id'])

    if row[0] #CODIGO
      row[0].strip!
      row[0].delete! '^A-Za-z|0-9'
    else
      return [0,0,0]
    end

    subject = Subject.find_or_initialize_by(code: row[0])

    nueva = subject.new_record?
    subject.area_id = area.id

    if row[1] #Nombre
      row[1].strip!
    else
      return [0,0,1]
    end
      
    subject.name = row[1]

    # UNITS CREIDTS
    credit = row[2] ? row[2].to_i : fields['unit_credits']
    subject.unit_credits = credit

    # ORDER
    order = row[3] ? row[3].to_i : fields['order']
    subject.ordinal = order

    # MODALITY
    # p "     #{row[4].strip.downcase.to_sym}      ".center(500, "!")
    modality = fields['modality']
    if row[4]
      aux = row[4].strip.downcase
      modality = aux if Subject.modalities.keys.include? aux
    end
    
    subject.modality = modality
      
    # QUALIFICATION TYPE
    qualification_type = row[5] ? row[5].strip.downcase.to_sym : fields['qualification_type']
    qualification_type = :numerica if qualification_type.eql? :numérica
      
    subject.qualification_type = qualification_type

    if subject.save
      if nueva
        total_newed = 1
      else
        total_updated = 1
      end
    else
      no_registred = 1
    end

    return [total_newed, total_updated, no_registred]
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
      self.paper_trail_event = "¡Asignatura eliminada!"
    end

end
