class Student < ApplicationRecord

  # SCHEMA:
  # t.boolean "active", default: true
  # t.integer "disability"
  # t.integer "nacionality"
  # t.integer "marital_status"
  # t.string "origin_country"
  # t.string "origin_city"
  # t.date "birth_date"  
  # t.string "grade_title"
  # t.string "grade_university"
  # t.integer "graduate_year"

  # GLOBALS VARIABLES:
  ESTADOS_CIVILES = ['Soltero/a', 'Casado/a', 'Concubinato', 'Divorciado/a', 'Viudo/a']
  NACIONALIDAD = ['Venezolano/a', 'Venezolano/a Nacionalizado/a', 'Extranjero/a']

  DISCAPACIDADES = ['Sensorial Visual', 'Sensorial Auditiva', 'Motora Miembros Inferiores', 'Motora Medios Superiores', 'Motora Ambos Miembros']

  enum nacionality: NACIONALIDAD
  enum disability: DISCAPACIDADES
  enum marital_status: ESTADOS_CIVILES

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  # ASSOCIATIONS:
  #belons_to
  belongs_to :user
  # accepts_nested_attributes_for :user
  # has_one
  has_one :address, dependent: :destroy
  accepts_nested_attributes_for :address
  # has_many
  has_many :grades, dependent: :destroy
  accepts_nested_attributes_for :grades, reject_if: proc { |attributes| attributes['study_plan_id'].blank? }
# creates avatar_attributes=

  has_many :study_plans, through: :grades
  has_many :admission_types, through: :grades
  has_many :enroll_academic_processes, through: :grades
  has_many :academic_records, through: :enroll_academic_processes

  # VALIDATIONS:
  validates :user, presence: true, uniqueness: true
  validates :grades, presence: true
  # validates :nacionality, presence: true, unless: :new_record?
  # validates :marital_status, presence: true, unless: :new_record?
  # validates :origin_country, presence: true, unless: :new_record?
  # validates :origin_city, presence: true, unless: :new_record?
  # validates :birth_date, presence: true, unless: :new_record?


  # validates :grades, presence: true
  # How to validate if student is not created for assosiation

  # SCOPES:
  scope :custom_search, -> (keyword) { joins(:user).where("users.ci ILIKE '%#{keyword}%' OR users.email ILIKE '%#{keyword}%' OR users.first_name ILIKE '%#{keyword}%' OR users.last_name ILIKE '%#{keyword}%' OR users.number_phone ILIKE '%#{keyword}%'") }

  scope :find_by_user_ci, -> (ci) {joins(:user).where('users.ci': ci).first}

  # CALLBACKS:
  after_destroy :check_user_for_destroy
  
  # HOOKS:
  def check_user_for_destroy
    user_aux = User.find self.user_id
    user_aux.delete if user_aux.without_rol?
  end


  # FUNCTIONS:
  def complete_info?
    !(empty_info? or (user and user.empty_info?) or (address and address.empty_info?))
  end

  def empty_info?
    nacionality.blank? or marital_status.blank? or origin_country.blank? or origin_city.blank? or birth_date.blank?
  end

  def self.countries
    require 'json'

    file = File.read("#{Rails.root}/public/countriesToCities.json")

    JSON.parse(file)
  end

  def name
    user.ci_fullname if user
  end

  def user_ci
    self.user.ci if self.user
  end

  # CALLBACKS:
  # HOOKS:

  # IMPORT:

  def self.before_import_find(record)
    if (ci = record[:ci])
      if (user = User.find_by_ci(ci))
        user.update(first_name: record[:first_name], last_name: record[:last_name], email: record[:email])
      else
        user = User.create(ci: record[:ci], first_name: record[:first_name], last_name: record[:last_name], email: record[:email])
      end
      self.user_id = user.id
    end 
    p "ESTOY AQUI 01"


    # if (study_plan = StudyPlan.find_by_code(record[:study_plan_code]) && admission_type = AdmissionType.find_by_code(record[:admission_type_name]))
    #   p "ESTOY AQUIIIIIII"
    #   self.grades.create(study_plan_id: study_plan.id, admission_type_id: admission_type.id)
    # end      
  end

  def after_import_save(record)
    if (study_plan = StudyPlan.find_by_code(record[:study_plan_code]) && admission_type = AdmissionType.find_by_code(record[:admission_type_name]))
      self.grades.create(study_plan_id: study_plan.id, admission_type_id: admission_type.id)
    end  
  end

  # def before_import_save(record)
  #   if (ci = record[:ci])
  #     if (user = User.find_by_ci(ci))
  #       user.update(record[:user])
  #     else
  #       user = User.create(record[:user])
  #     end
  #     self.user_id = user.id
  #   end
  # end

  # def before_import_save(record)
  #     self.user_id = record[:user_id]
  #     self.ci = record[:ci]
  # end
  # def before_import_save(row, map)
  #   self.created_nested_items(row, map)
  # end  
  
  rails_admin do
    navigation_label 'Gestión de Usuarios'
    navigation_icon 'fa-regular fa-user-graduate'
    weight 4

    update do
      field :user

      fields :grades, :address do
        inline_add false
      end

      fields :nacionality, :origin_country, :origin_city, :birth_date, :marital_status, :grade_title, :grade_university, :graduate_year

    end

    edit do
      field :user

      field :grades

      fields :nacionality, :origin_country, :origin_city, :birth_date, :marital_status, :grade_title, :grade_university, :graduate_year

    end

    show do
      field :user_personal_data do
        label 'Datos Personales'
        formatted_value do
          bindings[:view].render(partial: 'users/personal_data', locals: {user: bindings[:object].user})
        end        
      end
      field :description_grades do
        label 'Registro Académico'
        formatted_value do
          bindings[:view].render(partial: 'students/show', locals: {student: bindings[:object]})
        end
      end
      # fields :user, :grades, :nacionality, :origin_country, :origin_city, :birth_date, :marital_status, :address, :grade_title, :grade_university, :graduate_year, :created_at
    end

    list do
      search_by :custom_search

      field :user_image_profile do
        label 'Perfil'

        formatted_value do
          if (bindings[:object].user and bindings[:object].user.profile_picture and bindings[:object].user.profile_picture.attached? and bindings[:object].user.profile_picture.representable?)
            bindings[:view].render(partial: "layouts/set_image", locals: {image: bindings[:object].user.profile_picture, size: '30x30', alt: "foto perfil #{bindings[:object].user.nick_name}"})
          else
            false
          end
        end

      end

      field :user_ci do
        label 'Cédula'
        # sortable "users.ci"
        # queryable "users.ci"
        # searchable ['users.ci']
      end

      field :user_last_name do
        label 'Apellidos'
        # searchable [{:users => :last_name}]
      end
      field :user_first_name do
        label 'Nombres'
      end
      field :address_short do
        label 'Ciudad'
      end

      field :grade_admission_type do
        label 'Ingreso'
      end

      field :user_phone do
        label 'Número Telefónico'
      end
      field :user_email do
        label 'Email'
      end      

      :created_at
    end

    export do
      fields :user, :nacionality, :origin_country, :origin_city, :birth_date, :marital_status, :address, :created_at
    end

    import do
      field :ci
      field :email
      field :first_name
      field :last_name
      field :study_plan_code
      field :admission_type_name

      # mapping_key_list ['user[ci]', 'user[email]', 'user[first_name]','user[last_name]']
      # mapping_key_list ['ci', 'email', 'first_name','last_name']
    end

  end

  def user_ci
    user.ci if user
  end

  def user_last_name
    user.last_name if user
  end
  def user_first_name
    user.first_name if user
  end 
  def user_phone
    user.number_phone if user
  end 
  def user_email
    user.email if user
  end
  def address_short
    address.city_and_state if address
  end
  def grade_admission_type
    grades.map{|g| g.admission_type.name if g.admission_type}.to_sentence
  end

  def self.import row, fields

    total_newed = total_updated = 0
    no_registred = nil

    if row[0]
      row[0].strip!
      row[0].delete! '^0-9'
    else
      return [0,0,0]
    end
    
    usuario = User.find_or_initialize_by(ci: row[0])
    
    if row[1]
      row[1].strip!
      usuario.email = row[1]
    else
      return [0,0,1]
    end

    if row[2]
      row[2].strip!
      usuario.first_name = row[2]
    else
      return [0,0,2]
    end

    if row[3]
      row[3].strip!
      usuario.last_name = row[3] if row[3]
    else
      return [0,0,3]
    end


    if row[4]
      row[4].strip!
      row[4].delete! '^A-Za-z'
      row[4] = :Masculino if row[4].upcase.eql? 'M'
      row[4] = :Femenino if row[4].upcase.eql? 'F'
      usuario.sex = row[4] 
    end

    usuario.number_phone = row[5] if row[5]

    if usuario.save
      estudiante = Student.find_or_initialize_by(user_id: usuario.id)

      if estudiante.save
        grado = Grade.find_or_initialize_by(student_id: estudiante.id, study_plan_id: fields[:study_plan_id])
        grado.admission_type_id = fields[:admission_type_id]
        grado.registration_status = fields[:registration_status]
        nuevo_grado = grado.new_record?

        if grado.save
          if nuevo_grado
            total_newed = 1
          else
            total_updated = 1
          end
        else
          no_registred = row
        end
      else
        no_registred = row
      end
    else
      no_registred = row
    end

    [total_newed, total_updated, no_registred]
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
      self.paper_trail_event = "¡Estudiante eliminado!"
    end

end
