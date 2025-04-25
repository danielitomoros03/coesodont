class BankAccount < ApplicationRecord
  # t.string "code", null: false
  # t.string "holder", null: false
  # t.bigint "bank_id", null: false
  # t.bigint "school_id", null: false
  # t.integer "account_type"

  # ENUMERIZE:
  enum account_type: [:ahorro, :corriente]

  # ASSOCIATIONS:
  belongs_to :bank
  belongs_to :school

  # has_one :school

  validates_presence_of :code
  validates_presence_of :holder

  # FUNCTIONS:
  def name
    "#{code} #{holder} - #{account_type} : #{bank&.name}"
  end

  rails_admin do
    visible false
    navigation_label 'Administrativa'
    navigation_icon 'fa-solid fa-piggy-bank'

    edit do
      field :code do
        html_attributes do
          {:length => 20, :size => 20, :onInput => "$(this).val($(this).val().toUpperCase().replace(/[^0-9]/g,''))"}
        end
      end
      field :holder
      field :bank do
        inline_add false
        inline_edit false
      end
      field :account_type
      # field :short_desc do
      #   help 'A quíen va dirigida la cuenta'
      # end
    end

    export do
      exclude_fields :id, :created_at, :updated_at
    end
  end

end
