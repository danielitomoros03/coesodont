class StudentSessionController < ApplicationController
	before_action :set_session_id_if_multirols, only: [:dashboard]
	before_action :authenticate_student!

	layout 'student_portal'
	def dashboard
		# OCULATAMIENTO TEMPORAL DE DATOS PERSONALES:
		if current_user.empty_any_image?
			redirect_to edit_images_user_path(current_user)
		elsif current_user.empty_personal_info?
			redirect_to edit_user_path(current_user)
		elsif current_student.empty_info?
			redirect_to edit_student_path(current_student)
		elsif current_student.address.nil?
			redirect_to new_student_address_path(current_student.id)
		elsif current_student.address.empty_info?
			redirect_to edit_address_path(current_student)
		end

		@student = current_student
		@grades = @student.grades.includes(:study_plan, :school, :admission_type)
		@grade = @grades.find_by(id: params[:grade_id]) || @grades.first

		return unless @grade

		@proceso_activo = @grade.school&.active_process
		@inscripcion_actual = @proceso_activo && @grade.enroll_academic_processes.of_academic_process(@proceso_activo.id).first
		@records_en_curso = if @inscripcion_actual
			@inscripcion_actual.academic_records.no_retirados
				.includes(:subject, section: [:schedules, { teacher: :user }])
		else
			AcademicRecord.none
		end

	end

	# Cargado vía Turbo Frame lazy desde el dashboard: es la sección más pesada
	# (historial completo con calificaciones) y la menos urgente para el primer pintado.
	def historial
		@student = current_student
		@grades = @student.grades.includes(:study_plan, :school, :admission_type)
		@grade = @grades.find_by(id: params[:grade_id]) || @grades.first
		return head :no_content unless @grade

		proceso_activo = @grade.school&.active_process
		@historial = @grade.enroll_academic_processes
			.includes(:academic_process, academic_records: [:qualifications, :subject, :section])
			.sort_by_period
		@historial = @historial.where.not(academic_process_id: proceso_activo.id) if proceso_activo
		@serie_pps = @historial.reverse.filter_map do |eap|
			[eap.academic_process.period_name, eap.weighted_average.to_f.round(2)] if eap.weighted_average.to_f.positive?
		end

		render layout: false
	end
end
