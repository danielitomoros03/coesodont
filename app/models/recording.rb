module Recording

  def link_to_academic_records_csv_report
    if self.academic_records.any?
      # "<a href='/export_csv/academic_records/#{self.id}?model_name=#{self.class.name}' title='Descargar Registros Académicos' class='label bg-success'><i class='fa fa-user-graduate'></i><i class='fa fa-down-long'></i></a>".html_safe
      ApplicationController.helpers.link_academic_records_csv self
    else
      nil
    end
  end

end
