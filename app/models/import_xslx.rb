class ImportXslx

	def self.import_by_console url, fields, entity

		require 'simple_xlsx_reader'
		require 'csv'

		doc = SimpleXlsxReader.open(url)
				
		hoja = doc.sheets.first
		
		hoja.rows.shift if hoja.headers.include? nil
		headers = hoja.headers
		rows = hoja.data
		
		total_added = 0
		total_updated = 0
		total_errors = 0
		errors = []
		
		CSV.open("/Users/danielmoros/Documents/desarrollo/COESODON/data_para_migrar/#{entity.to_s}_errores.csv", "w") do |errores_file|
			# Enviar errores por correo
			# Incluir fecha
			rows.each_with_index do |row,i|
				print "#{i}:"
				respond = entity.import row, fields
				if respond[0].eql? 1
					aux = 'A'
					total_added += 1
				elsif respond[1].eql? 1
					aux = 'U'
					total_updated += 1
				else
					errores_file << row
					aux = 'X'
					total_errors += 1
					errors += respond
				end

				print " #{aux},"
			end
			
		end
		p "---- Proceso completado -----"
		p "Resumen:"
		p "Toral registros: #{rows.count}"
		p "Toral agregados: #{total_added}"
		p "Toral actualizados: #{total_updated}"
		p "Toral Errores: #{total_errors}"
		p "Detalles: #{errors}" if errors.any?
	end

	def self.import_students_by_console
		
		import_by_console '/Users/danielmoros/Documents/desarrollo/COESODON/data_para_migrar/inscritos_totales.xlsx', {study_plan_id: 3, admission_type_id: AdmissionType.first.id, console: true}, Student

	end

	def self.import_academic_records_by_console

		import_by_console '/Users/danielmoros/Documents/desarrollo/COESODON/data_para_migrar/final_registros_academicos_con_errores.xlsx', {nombre_periodo: nil, study_plan_id: StudyPlan.first.id}, AcademicRecord
	end


	def self.general_import fields, headers_layout
		require 'simple_xlsx_reader'

		errores_cabeceras = []

		begin
			doc = SimpleXlsxReader.open(fields[:datafile].tempfile)
			hoja = doc.sheets.first

			hoja.rows.shift if hoja.headers.include? nil
			headers = hoja.headers
			rows = hoja.data
			headers.compact!

		rescue Exception => e
			errores_cabeceras << "Error al intentar abrir el archivo: #{e}"
		end


		if errores_cabeceras.any?
			errores_cabeceras << headers
			return [0,0, errores_cabeceras]
		else		
			errors = []
			error_type = 1
			total_newed = 0
			total_updated = 0
			resumen = ""
			row_record = ''
			row_index = 0

			begin
				rows.each_with_index do |row, i|
					row_record = row
					row_index = i

					sum_newed, sum_updated, sum_errors = fields[:entity].singularize.camelize.constantize.import row, fields
					unless sum_errors.blank?
						sum_errors = "#{(65+sum_errors).chr}" if sum_errors.is_a? Integer and sum_errors >= 0 and sum_errors < 6
						errors << "#{i+1}:#{sum_errors}"
					end
					total_newed += sum_newed
					total_updated += sum_updated
					
					break if errors.count > 50
					if i > 499
						errors << 'limit_records'
						break
					end
				end

			rescue Exception => e
				errors << "Fila #{row_index} #{e} "
			end

			return [total_newed, total_updated, errors.uniq]
		end

	end

end