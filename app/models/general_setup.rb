class GeneralSetup < ApplicationRecord

  def self.enabled_post_qualification?
    var = GeneralSetup.where(clave: "ENABLED_POST_QUALIFICACION").first
    (var&.valor&.casecmp("SI") == 0 or var&.valor&.casecmp("SÍ") == 0) ? true : false
  end

  def self.send_wellcome_mailer_on_create_user? 
    
    var = GeneralSetup.where(clave: "SEND_WELLCOME_MAILER_ON_CREATE_USER").first
    (var&.valor&.casecmp("SI") == 0 or var&.valor&.casecmp("SÍ") == 0) ? true : false
  end

end
