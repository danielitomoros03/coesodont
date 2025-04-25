class AddForceAbsoluteToSubject < ActiveRecord::Migration[7.0]
  def change
    add_column :subjects, :force_absolute, :boolean, default: false
  end
end
