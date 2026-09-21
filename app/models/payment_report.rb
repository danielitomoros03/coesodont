class PaymentReport < ApplicationRecord
  # SCHEMA:
  # t.float "amount"
  # t.string "transaction_id"
  # t.integer "transaction_type"
  # t.date "transaction_date"
  # t.bigint "origin_bank_id", null: false
  # t.string "payable_type"
  # t.bigint "payable_id"  
  # t.bigint "receiving_bank_account_id"  

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  # Enum:
  enum status: [:Pendiente, :Validado, :Invalidado]

  # ASSOCIATIONS:
  belongs_to :origin_bank, class_name: 'Bank', foreign_key: 'origin_bank_id'
  belongs_to :payable, polymorphic: true
  belongs_to :receiving_bank_account, class_name: 'BankAccount'

  # En la práctica todo payable es un EnrollAcademicProcess (Grade no tiene pagos).
  # Esta asociación no-polimórfica permite joinear/filtrar por período en RailsAdmin
  # y exponer student/user como asociaciones (secciones propias en el export).
  belongs_to :enroll_academic_process, foreign_key: :payable_id, optional: true
  has_one :student, through: :enroll_academic_process
  has_one :user, through: :enroll_academic_process

  has_one_attached :voucher do |attachable|
    attachable.variant :thumb, resize_to_limit: [100,100]
  end

  scope :todos, -> {where('0 = 0')}
  scope :grades, -> {where(payable_type: 'Grade')}  
  scope :enroll_academic_processes, -> {where(payable_type: 'EnrollAcademicProcess')}  

  scope :custom_search, -> (keyword) {
    joins_student_user
      .joins("INNER JOIN academic_processes ON enroll_academic_processes.academic_process_id = academic_processes.id")
      .where(
        "academic_processes.name ILIKE :k OR users.ci ILIKE :k OR users.first_name ILIKE :k OR users.last_name ILIKE :k OR (users.first_name || ' ' || users.last_name) ILIKE :k OR users.email ILIKE :k OR users.number_phone ILIKE :k OR payment_reports.depositor_name ILIKE :k OR payment_reports.depositor_ci ILIKE :k",
        k: "%#{keyword}%"
      )
  }

  scope :joins_enroll_academic_process, -> {joins("INNER JOIN enroll_academic_processes ON enroll_academic_processes.id = payment_reports.payable_id AND payment_reports.payable_type = 'EnrollAcademicProcess'")}

  # grades.student_id apunta a students.user_id, que es el mismo id de users.
  scope :joins_student_user, -> {
    joins_enroll_academic_process
      .joins("INNER JOIN grades ON grades.id = enroll_academic_processes.grade_id")
      .joins("INNER JOIN users ON users.id = grades.student_id")
  }

  attr_accessor :remove_voucher
  after_save { voucher.purge if remove_voucher.eql? '1' }   

  # VALIDATIONS:
  # validates :payable_id, presence: true
  # validates :payable_type, presence: true
  validates :payable, presence: true
  validates :amount, presence: true
  validates :transaction_id, presence: true
  validates :transaction_type, presence: true
  validates :transaction_date, presence: true
  validates :origin_bank, presence: true
  validates :receiving_bank_account, presence: true
  validates :voucher, presence: true
  validates :status, presence: true
  validate :voucher_size_within_limit

  enum transaction_type: [:transferencia, :efectivo, :punto_venta]

  def name
    "#{transaction_id} - #{amount_to_bs}"
  end

  def academic_process
    payable&.academic_process
  end

  def period
    academic_process&.period
  end

  def amount_to_bs
    ActionController::Base.helpers.number_to_currency(self.amount, unit: 'Bs.', separator: ",", delimiter: ".")
  end

  def label_status readonly=false
    case status
    when "Invalidado"
      ApplicationController.helpers.label_status("bg-danger", self.status&.titleize)
    when "Validado"
      ApplicationController.helpers.label_status("bg-success", self.status&.titleize)
    else
      if readonly
        ApplicationController.helpers.label_status("bg-warning mx-2", self.status&.titleize)
      else
        aux = ApplicationController.helpers.label_status("bg-warning mx-2", self.status&.titleize)
        aux += "<a href='/payment_reports/#{self.id}/quick_validation?payment_report[status]=Validado' class='label label-sm bg-success' data-bs-placement='right' data-bs-original-title='Validación rápida' rel='tooltip' data-bs-toggle='tooltip'><i class='fa fa-check'></i></a>".html_safe
        aux.html_safe
      end
    end    
  end

  rails_admin do
    navigation_label 'Administrativa'
    navigation_icon 'fa-solid fa-cash-register'

    list do
      search_by :custom_search
      scopes [:todos, :Pendiente, :Validado, :Invalidado]
      field :id do
        sticky true
      end

      field :created_at do
        sticky true
        # El filtro por día vive en :registered_on; la columna conserva la hora.
        filterable false
      end

      # created_at es datetime y RailsAdmin lo parsea con Time.zone.parse: filtrar
      # pedía una hora y comparaba el instante exacto, así que elegir un día no
      # devolvía nada. Declarado :date el picker no muestra reloj y parse_value da un
      # Date; la columna se declara :datetime para que expanda el día completo
      # (build_statement_for_datetime_or_timestamp sólo hace beginning_of_day..
      # end_of_day cuando el valor es un Date).
      field :registered_on, :date do
        label 'Fecha Registro'
        visible false
        sortable false
        filterable true
        searchable_columns [{ column: 'payment_reports.created_at', type: :datetime }]
      end
      field :status do
        sticky true
        pretty_value do
          bindings[:object].label_status
        end
      end

      field :amount
      field :period, :enum do
        label 'Periodo'
        searchable [{ AcademicProcess => :period_id }]
        eager_load(enroll_academic_process: :academic_process)
        sortable :name
        enum do
          Period.options_with_data(enroll_academic_processes: :payment_reports)
        end
        pretty_value do
          bindings[:object].period&.name || ' - '
        end
      end
      field :student do
        # Resuelto sobre :user, que los filtros de abajo ya precargan. Ir por .student
        # costaba dos queries por fila (la asociación y su user) para llegar al mismo
        # registro: students tiene user_id de clave primaria, así que student.id es user.id.
        pretty_value do
          user = bindings[:object].user
          "<a href='/admin/student/#{user&.id}'>#{user&.ci_fullname}</a>".html_safe
        end
      end

      # Datos del estudiante como filtros de "Agregar Filtro". Van invisibles porque
      # la columna Estudiante ya los muestra: RailsAdmin arma el menú de filtros con
      # list.fields (todos), pero la tabla sólo con los visibles.
      [
        [:student_ci,        'CI del Estudiante',        'users.ci'],
        [:student_names,     'Nombres del Estudiante',   'users.first_name'],
        [:student_lastnames, 'Apellidos del Estudiante', 'users.last_name'],
        [:student_email,     'Correo del Estudiante',    'users.email'],
        [:student_phone,     'Teléfono del Estudiante',  'users.number_phone']
      ].each do |field_name, field_label, column|
        field field_name do
          label field_label
          visible false
          sortable false
          eager_load :user
          searchable column
          # Sin esto el operador arranca en "..." (_discard) y el filtro se ignora en silencio.
          default_filter_operator 'like'
        end
      end
      # field :payable_name do
      #   label 'Descripción'
      #   formatted_value do
      #     bindings[:object].payable.name
      #   end
      # end

      fields :transaction_id, :transaction_type, :transaction_date, :origin_bank, :receiving_bank_account
      field :voucher do
        filterable false

        formatted_value do
          if (bindings[:object].voucher&.attached? and bindings[:object].voucher&.representable?)
            bindings[:view].render(partial: "layouts/set_image", locals: {image: bindings[:object].voucher, size: '30x30'})
          else
            false
          end
        end
      end
      fields :depositor_name, :depositor_ci
    end

    show do
      fields :id, :created_at, :amount, :status, :transaction_id, :transaction_type, :transaction_date, :origin_bank, :receiving_bank_account, :voucher, :depositor_name, :depositor_ci
    end

    edit do
      field :amount
      field :transaction_id do
        html_attributes do
          {:length => 20, :size => 20, :onInput => "$(this).val($(this).val().toUpperCase().replace(/[^0-9]/g,''))"}
        end
      end
      field :status
      field :payable do
        label 'Entidad a Pagar'
      end
      fields :transaction_type, :transaction_date
      field :origin_bank do
        inline_edit false
        inline_add false
      end
      field :receiving_bank_account do
        inline_edit false
        inline_add false
      end
      fields :voucher, :depositor_name, :depositor_ci
    end

    export do
      fields :id, :created_at, :amount, :transaction_id, :transaction_type, :transaction_date, :origin_bank, :origin_bank, :depositor_name, :depositor_ci
      field :payable_type do
        label 'Tipo'
      end
      # field :payable_id do
      #   label 'Id'
      # end

      field :payable_name do
        label 'Descripción'
        # El filtro de período (definido en la sección :list) referencia
        # academic_processes; en export su JOIN sólo existe si algún campo lo
        # eager-loadea. Lo cargamos aquí para no romper el export al filtrar por período.
        eager_load(enroll_academic_process: :academic_process)
        formatted_value do
          bindings[:object].payable.name
        end
      end

      # Cada asociación se exporta como su propia sección ("Campos asociados de …"),
      # usando el bloque export de Student/User. Labels vía activerecord.attributes en es.yml.
      field :student do
        eager_load true
      end
      field :user do
        eager_load true
      end
    end
  end  

  private

    def voucher_size_within_limit
      return unless voucher.attached?
      return if voucher.byte_size <= 20.megabytes

      errors.add(:voucher, "es muy grande (#{(voucher.byte_size / 1.megabyte.to_f).round(1)} MB). El máximo permitido es 20 MB. Comprime la imagen antes de subirla.")
    end

    def paper_trail_update
      changed_fields = self.changes.keys - ['created_at', 'updated_at']
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      if self.status_changed?
        self.paper_trail_event = "¡#{object} #{self.status}!"
      else
        self.paper_trail_event = "¡#{object} actualizado!"
        # self.paper_trail_event = "¡#{object} actualizado en #{changed_fields.to_sentence}"
      end
    end  

    def paper_trail_create
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} registrado!"
    end  

    def paper_trail_destroy
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡Reporte de Pago eliminado!"
    end

end
