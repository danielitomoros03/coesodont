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

  has_one_attached :voucher do |attachable|
    attachable.variant :thumb, resize_to_limit: [100,100]
  end

  scope :todos, -> {where('0 = 0')}
  scope :grades, -> {where(payable_type: 'Grade')}  
  scope :enroll_academic_processes, -> {where(payable_type: 'EnrollAcademicProcess')}  

  scope :custom_search, -> (keyword) {joins_enroll_academic_process.joins("INNER JOIN academic_processes ON enroll_academic_processes.academic_process_id = academic_processes.id").where("academic_processes.name ILIKE '%#{keyword}%'") }

  scope :joins_enroll_academic_process, -> {joins("INNER JOIN enroll_academic_processes ON enroll_academic_processes.id = payment_reports.payable_id AND payment_reports.payable_type = 'EnrollAcademicProcess'")}

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

  enum transaction_type: [:transferencia, :efectivo, :punto_venta]

  def name
    "#{transaction_id} - #{amount_to_bs}"
  end

  def student
    payable&.student
  end

  def user
    student&.user
  end

  def academic_process
    payable&.academic_process
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
      field :id
      field :created_at
      field :amount
      field :academic_process do
        label 'Period'
        formatted_value do
          bindings[:object].academic_process&.name
        end
      end
      field :student do
        pretty_value do
          "<a href='/admin/student/#{bindings[:object].student&.id}'>#{bindings[:object].student&.user&.ci_fullname}</a>".html_safe
        end
      end
      field :payable_name do
        label 'Descripción'
        formatted_value do
          bindings[:object].payable.name
        end
      end

      fields :transaction_id, :transaction_type, :transaction_date, :origin_bank, :receiving_bank_account
      field :status do
        pretty_value do
          bindings[:object].label_status
        end
      end
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
      field :payable_id do
        label 'Id'
      end

      field :payable_name do
        label 'Descripción'
        formatted_value do
          bindings[:object].payable.name
        end
      end

      field :user_name do
        label 'Nombre Usuario'
        formatted_value do
          bindings[:object].student.user.first_name
        end
      end

      field :user_last_name do
        label 'Apellido Usuario'
        formatted_value do
          bindings[:object].student.user.last_name
        end
      end
      
      field :user_ci do
        label 'Ci Usuario'
        formatted_value do
          bindings[:object].student.user.ci
        end
      end    

    end
  end  

  private


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
