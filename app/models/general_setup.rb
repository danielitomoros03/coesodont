class GeneralSetup < ApplicationRecord

  EDAD_MINIMA_ESTUDIANTE_DEFAULT = 16

  # Edad mínima (años) exigida a la fecha de nacimiento del estudiante.
  # Configurable desde la app (clave EDAD_MINIMA_ESTUDIANTE); usa el default si
  # la clave no existe o trae un valor no numérico.
  def self.edad_minima_estudiante
    valor = GeneralSetup.where(clave: "EDAD_MINIMA_ESTUDIANTE").first&.valor.to_i
    valor.positive? ? valor : EDAD_MINIMA_ESTUDIANTE_DEFAULT
  end

  def self.enabled_post_qualification?
    var = GeneralSetup.where(clave: "ENABLED_POST_QUALIFICACION").first
    (var&.valor&.casecmp("SI") == 0 or var&.valor&.casecmp("SÍ") == 0) ? true : false
  end

  def self.send_wellcome_mailer_on_create_user? 
    
    var = GeneralSetup.where(clave: "SEND_WELLCOME_MAILER_ON_CREATE_USER").first
    (var&.valor&.casecmp("SI") == 0 or var&.valor&.casecmp("SÍ") == 0) ? true : false
  end

end
