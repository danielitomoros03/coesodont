# El premio por la carrera quedó directo en el código de ODON (Daniel, 9-nov-2026): la clave que lo encendía ya no
# se lee. Se borra para que Configuración General no muestre un interruptor que no hace nada.
class RemovePremioMeritoPorCarrera < ActiveRecord::Migration[7.0]
  def up
    GeneralSetup.where(clave: 'PREMIO_MERITO_POR_CARRERA').destroy_all
  end

  def down
    # Nada que devolver: ningún código la lee.
  end
end
