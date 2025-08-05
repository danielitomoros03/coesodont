desc "Importación inicial de estudiantes"
task :import_students_by_console => :environment do
	begin
		p "Iniciando..."
		ImportXslx.import_students_by_console
	rescue Exception => e
			p "Error: <#{e}>"
	end	
end

desc "Importación inicial de registros históricos"
task :import_academic_records_by_console => :environment do
	begin
		p "Iniciando..."
		ImportXslx.import_academic_records_by_console
	rescue Exception => e
			p "Error: <#{e}>"
	end	
end

desc "Actualiza todas inscripciones segun el reglamento"
task :update_all_enrollment_status => :environment do
	begin
		p 'iniciando... '
		AcademicProcess.reorder(name: :asc).each do |ap|
			p "Periodo: #{ap.period_name}"
			ap.enroll_academic_processes.each do |eap| 
				if eap.finished?
					print eap.update(permanence_status: eap.get_regulation) ? '.' : 'x'

				else
					print "-#{eap.id}-"
				end
			end
			p "/"
    	end

	rescue StandardError => e
		p e
	end
	
end

desc "Actualiza los numeritos de las inscripciones"
task :update_enroll_academic_processes_numbers => :environment do
	begin
		p 'iniciando... '
		AcademicProcess.reorder(name: :asc).each do |ap|
			p "Periodo: #{ap.period_name}"
			ap.enroll_academic_processes.each do |eap| 


				print eap.update(efficiency: eap.calculate_efficiency, simple_average: eap.calculate_average, weighted_average: eap.calculate_weighted_average) ? '.' : "x#{eap.id}"
			end
			p "/"
		end

	rescue StandardError => e
		p e
	end
	
end


  def update_all_efficiency

    Grados.each do |gr| 
      academic_records = gr.academic_records
      cursados = academic_records.total_credits_coursed
      aprobados = academic_records.total_credits_approved

      eficiencia = (cursados and cursados > 0) ? (aprobados.to_f/cursados.to_f).round(4) : 0.0

      aux = academic_records.coursed

      promedio_simple = aux ? aux.round(4) : 0.0

      aux = academic_records.weighted_average
      ponderado = (cursados > 0) ? (aux.to_f/cursados.to_f).round(4) : 0.0
    end

  end

desc "Actualiza los valores start_process_id nulos de Grade con el período académico de la primera inscripción"
task :update_start_process_id_nulls_complete => :environment do
  begin
    p "Iniciando actualización de start_process_id nulos con ordenamiento completo..."
    
    # Encontrar todos los grades con start_process_id nulo
    grades_with_null_start = Grade.where(start_process_id: nil)
    total_grades = grades_with_null_start.count
    
    p "Total de grades con start_process_id nulo: #{total_grades}"
    
    updated_count = 0
    error_count = 0
    
    grades_with_null_start.find_each do |grade|
      begin
        # Buscar la primera inscripción del estudiante con ordenamiento completo
        # Primero por año, luego por tipo de período, luego por ID del período
        first_enrollment = grade.enroll_academic_processes
                               .joins(academic_process: {period: :period_type})
                               .order('periods.year ASC, periods.id ASC')
                               .first
        
        if first_enrollment
          # Actualizar el start_process_id con el academic_process_id de la primera inscripción
          # y también actualizar el permanence_status del first_enrollment a nuevo
          if grade.update(start_process_id: first_enrollment.academic_process_id) && 
             first_enrollment.update(permanence_status: :nuevo)
            updated_count += 1
            print "."
          else
            error_count += 1
            print "x"
          end
        else
          # Si no tiene inscripciones, marcar como error
          error_count += 1
          print "e"
          p "Grade ID #{grade.id} (Estudiante: #{grade.user&.ci || 'N/A'}) no tiene inscripciones"
        end
      rescue => e
        error_count += 1
        print "E"
        p "Error procesando Grade ID #{grade.id}: #{e.message}"
      end
    end
    
    p ""
    p "Resumen:"
    p "- Total procesados: #{total_grades}"
    p "- Actualizados exitosamente: #{updated_count}"
    p "- Errores: #{error_count}"
    p "Tarea completada."
    
  rescue StandardError => e
    p "Error general en la tarea: #{e.message}"
    p e.backtrace.first(5)
  end
end

desc "Simula la actualización de start_process_id nulos sin hacer cambios reales"
task :simulate_start_process_id_update => :environment do
  begin
    p "Simulando actualización de start_process_id nulos..."
    
    # Encontrar todos los grades con start_process_id nulo
    grades_with_null_start = Grade.where(start_process_id: nil)
    total_grades = grades_with_null_start.count
    
    p "Total de grades con start_process_id nulo: #{total_grades}"
    
    would_update_count = 0
    error_count = 0
    no_enrollment_count = 0
    
    grades_with_null_start.limit(10).each do |grade| # Limitamos a 10 para la simulación
      begin
        # Buscar la primera inscripción del estudiante con ordenamiento completo
        first_enrollment = grade.enroll_academic_processes
                               .joins(academic_process: {period: :period_type})
                               .order('periods.year ASC, periods.id ASC')
                               .first
        
        if first_enrollment
          would_update_count += 1
          print "."
          p "Grade ID #{grade.id} (Estudiante: #{grade.user&.ci || 'N/A'}) -> AcademicProcess ID #{first_enrollment.academic_process_id} (#{first_enrollment.academic_process.period.name})"
          p "  - start_process_id: nil -> #{first_enrollment.academic_process_id}"
          p "  - permanence_status: #{first_enrollment.permanence_status} -> nuevo"
        else
          no_enrollment_count += 1
          print "e"
          p "Grade ID #{grade.id} (Estudiante: #{grade.user&.ci || 'N/A'}) no tiene inscripciones"
        end
      rescue => e
        error_count += 1
        print "E"
        p "Error procesando Grade ID #{grade.id}: #{e.message}"
      end
    end
    
    p ""
    p "Simulación completada (primeros 10 registros):"
    p "- Total procesados: #{grades_with_null_start.limit(10).count}"
    p "- Se actualizarían: #{would_update_count}"
    p "- Sin inscripciones: #{no_enrollment_count}"
    p "- Errores: #{error_count}"
    p "Para ejecutar la actualización real, use: rake update_start_process_id_nulls_complete"
    
  rescue StandardError => e
    p "Error general en la simulación: #{e.message}"
    p e.backtrace.first(5)
  end
end

desc "Actualiza el permanence_status a nuevo de todos los enroll_academic_process que son primeros de sus respectivos grade"
task :update_first_enrollments_to_nuevo => :environment do
  begin
    p "Iniciando actualización de permanence_status a nuevo para primeros enrollments..."
    
    updated_count = 0
    error_count = 0
    total_processed = 0
    
    # Procesar cada grade
    Grade.find_each do |grade|
      begin
        # Buscar la primera inscripción del estudiante ordenada por año del período
        first_enrollment = grade.enroll_academic_processes
                               .joins(academic_process: {period: :period_type})
                               .order('periods.year ASC, periods.id ASC')
                               .first
        
        if first_enrollment
          total_processed += 1
          
          # Solo actualizar si el permanence_status no es ya nuevo
          if first_enrollment.permanence_status != 'nuevo'
            if first_enrollment.update(permanence_status: :nuevo)
              updated_count += 1
              print "."
            else
              error_count += 1
              print "x"
            end
          else
            print "-" # Ya está en nuevo
          end
        end
      rescue => e
        error_count += 1
        print "E"
        p "Error procesando Grade ID #{grade.id}: #{e.message}"
      end
    end
    
    p ""
    p "Resumen:"
    p "- Total de grades procesados: #{total_processed}"
    p "- Actualizados exitosamente: #{updated_count}"
    p "- Errores: #{error_count}"
    p "Tarea completada."
    
  rescue StandardError => e
    p "Error general en la tarea: #{e.message}"
    p e.backtrace.first(5)
  end
end

# Simulación de la tarea de actualización de Primer Enrollment
desc "Simula la actualización de permanence_status a nuevo para primeros enrollments"
task :simulate_update_first_enrollments_to_nuevo => :environment do
  begin
    p "Simulando actualización de permanence_status a nuevo para primeros enrollments..."
    
    would_update_count = 0
    already_nuevo_count = 0
    error_count = 0
    total_processed = 0
    
    # Procesar solo los primeros 10 grades para la simulación
    Grade.limit(10).each do |grade|
      begin
        # Buscar la primera inscripción del estudiante ordenada por año del período
        first_enrollment = grade.enroll_academic_processes
                               .joins(academic_process: {period: :period_type})
                               .order('periods.year ASC, periods.id ASC')
                               .first
        
        if first_enrollment
          total_processed += 1
          
          if first_enrollment.permanence_status != 'nuevo'
            would_update_count += 1
            print "."
            p "Grade ID #{grade.id} (Estudiante: #{grade.user&.ci || 'N/A'}) - Enroll ID #{first_enrollment.id}"
            p "  - permanence_status: #{first_enrollment.permanence_status} -> nuevo"
            p "  - Período: #{first_enrollment.academic_process.period.name}"
          else
            already_nuevo_count += 1
            print "-"
            p "Grade ID #{grade.id} (Estudiante: #{grade.user&.ci || 'N/A'}) - Ya tiene permanence_status: nuevo"
          end
        end
      rescue => e
        error_count += 1
        print "E"
        p "Error procesando Grade ID #{grade.id}: #{e.message}"
      end
    end
    
    p ""
    p "Simulación completada (primeros 10 grades):"
    p "- Total procesados: #{total_processed}"
    p "- Se actualizarían: #{would_update_count}"
    p "- Ya están en nuevo: #{already_nuevo_count}"
    p "- Errores: #{error_count}"
    p "Para ejecutar la actualización real, use: rake update_first_enrollments_to_nuevo"
    
  rescue StandardError => e
    p "Error general en la simulación: #{e.message}"
    p e.backtrace.first(5)
  end
end

