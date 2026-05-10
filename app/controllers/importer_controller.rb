class ImporterController < ApplicationController
	COLUMN_NAMES = {
		'students'         => %w[cédula email nombres apellidos sexo teléfono periodo_ingreso tipo_admisión fecha_nacimiento],
		'teachers'         => %w[cédula email nombres apellidos sexo teléfono],
		'subjects'         => %w[código nombre créditos modalidad tipo_de_calificación],
		'sections'         => %w[número_de_sección código capacidad cédula_del_profesor],
		'academic_records' => %w[cédula código_de_asignatura número_de_sección período nota]
	}.freeze

	REQUIRED_FIELDS = {
		'subjects'         => ['id', 'nombre'],
		'students'         => ['ci', 'email', 'nombres', 'apellidos'],
		'teachers'         => ['ci', 'email', 'nombres', 'apellidos'],
		'sections'         => ['numero', 'codigo', 'capacidad', 'profesor_ci'],
		'academic_records' => ['ci', 'codigo', 'numero']
	}.freeze

	def entities
		entity = params[:entity]
		require_fields = REQUIRED_FIELDS[entity]

		unless require_fields
			flash[:danger] = 'Tipo de entidad no encontrada. Por favor inténtelo nuevamente.'
			return redirect_back(fallback_location: root_path)
		end

		begin
			total_newed, total_updated, errors, skipped_blank = ImportXslx.general_import(params, require_fields)
			limit_hit = errors.delete('limit_records')

			if errors.empty?
				flash[:success] = build_summary(entity, total_newed, total_updated, skipped_blank)
				flash[:warning] = limit_warning if limit_hit
				redirect_to "/admin/#{entity.singularize}"
			else
				processed = total_newed + total_updated
				severity  = processed.zero? ? :danger : :warning
				flash[severity] = build_message(entity, total_newed, total_updated, skipped_blank, errors, limit_hit)
				redirect_back(fallback_location: root_path)
			end
		rescue StandardError => e
			flash[:danger] = "Error General: #{e}"
			redirect_back(fallback_location: root_path)
		end
	end

	private

	def build_message(entity, newed, updated, skipped, errors, limit_hit)
		summary = build_summary(entity, newed, updated, skipped, errors.size)
		detail  = errors.map { |e| humanize_error(entity, e) }.to_sentence

		parts = []
		parts << truncation_warning if errors.size > 50
		parts << summary
		parts << "Detalles: #{detail}."
		parts << academic_records_hint if entity == 'academic_records'
		parts << limit_warning if limit_hit
		parts.join(' ')
	end

	def humanize_error(entity, error)
		return error unless error.is_a?(String)

		if (match = error.match(/\A(\d+):([A-Z])\z/))
			row_num, letter = match[1], match[2]
			"Fila #{row_num}: falta #{column_name(entity, letter)}"
		else
			error
		end
	end

	def column_name(entity, letter)
		index = letter.ord - 'A'.ord
		COLUMN_NAMES.dig(entity, index) || "columna #{letter}"
	end

	def build_summary(entity, newed, updated, skipped, error_count = 0)
		noun = entity == 'students' ? 'estudiante' : 'registro'
		parts = []
		parts << "#{newed} #{noun.pluralize(newed)} #{'creado'.pluralize(newed)}" if newed.positive?
		parts << "#{updated} #{'actualizado'.pluralize(updated)}" if updated.positive?
		parts << "#{skipped} #{'fila'.pluralize(skipped)} #{'vacía'.pluralize(skipped)} #{'ignorada'.pluralize(skipped)}" if skipped.positive?
		parts << "#{error_count} con problemas" if error_count.positive?
		parts.empty? ? 'No se procesó ningún registro.' : (parts.to_sentence.capitalize + '.')
	end

	def limit_warning
		'¡El archivo contiene más de 500 registros! Se procesaron los primeros 500 y quedaron pendientes el resto. Por favor, divida el archivo y realice una nueva carga.'
	end

	def truncation_warning
		'Más de 50 registros tienen problemas, por lo que no se continuó el proceso de carga.'
	end

	def academic_records_hint
		'Corrobore en el sistema que tanto el código de la asignatura como la cédula del estudiante existen. De no encontrarse la sección se creará siempre y cuando la asignatura exista. Revise los valores en el archivo de carga e inténtelo nuevamente.'
	end
end
