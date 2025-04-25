class CreateGeneralSetups < ActiveRecord::Migration[7.0]
  def change
    create_table :general_setups do |t|
      t.string :clave
      t.string :valor
      t.string :description

      t.timestamps
    end

    GeneralSetup.create(clave: 'ENABLED_POST_QUALIFICACION', valor: 'NO', description: 'Activa/Desactiva las calificaciones posteriores')
  end
end
