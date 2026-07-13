class SeedEdadMinimaEstudianteGeneralSetup < ActiveRecord::Migration[7.0]
  # Crea la clave de configuración editable desde el admin. Idempotente: no
  # pisa el valor si un admin ya lo ajustó.
  def up
    GeneralSetup.find_or_create_by!(clave: "EDAD_MINIMA_ESTUDIANTE") do |gs|
      gs.valor = GeneralSetup::EDAD_MINIMA_ESTUDIANTE_DEFAULT.to_s
      gs.description = "Edad mínima (años) exigida a la fecha de nacimiento del estudiante en el formulario de datos."
    end
  end

  def down
    GeneralSetup.where(clave: "EDAD_MINIMA_ESTUDIANTE").destroy_all
  end
end
