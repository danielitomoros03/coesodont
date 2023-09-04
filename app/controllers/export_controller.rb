class ExportController < ApplicationController
  before_action :logged_as_admin?

  def xls
    if params[:grades_others] and params[:id]
      academic_process = AcademicProcess.find params[:id]
      list = academic_process.invalid_grades_to_csv
      title = "No Validos para Cita Horaria #{academic_process.name}"
    end
    respond_to do |format|
      format.xls {send_data list, filename: "#{title}.xls"}
    end
  end

end
