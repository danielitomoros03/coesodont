class Authorized < ApplicationRecord
  # SCHEMA
  # t.bigint "admin_id", null: false
  # t.bigint "authorizable", null: false
  # t.boolean "can_create", default: false
  # t.boolean "can_read", default: false
  # t.boolean "can_update", default: false
  # t.boolean "can_delete", default: false
  # t.boolean "can_import", default: false
  # t.boolean "can_export", default: false

  belongs_to :admin
  belongs_to :authorizable

  def authorizable_klazz_constantenize
    authorizable.klazz.constantize if authorizable
  end

  def can_manage?
    can_create? or can_update?
  end

  def can_all?
    aux = true
    if authorizable
      aux = (aux and can_import) if Authorizable::IMPORTABLES.include? authorizable.klazz
      aux = (aux and can_export) unless Authorizable::UNEXPORTABLES.include? authorizable.klazz 
      aux = (aux and can_delete) unless Authorizable::UNDELETABLES.include? authorizable.klazz 
      aux = (aux and can_create) unless Authorizable::UNCREABLES.include? authorizable.klazz
    else
      aux = false
    end 
    aux
  end

  def cannot_all?
    (!can_create and !can_read and !can_update and !can_delete)
  end

  rails_admin do
    visible false
  end
end
