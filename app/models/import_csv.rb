class ImportCsv
	def self.import_students file, study_plan_id, admission_type_id, registration_status, send_welcome_emails= false
		require 'csv'
		# Totales
		# Usuarios
		total_usuarios_nuevos = 0
		total_usuarios_actualizados = 0
		#Estudiantes
		total_estudiantes_nuevos = 0
		total_estudiantes_actualizados = 0
		#Grados
		total_grados_nuevos = 0
		total_grados_actualizados = 0

		#No agregados
		usuarios_no_agregados = []
		estudiantes_no_agregados = []
		grados_no_agregados = []

		#Errores
		errores_generales = []
		errores_cabeceras = []
		estudiates_con_plan_errado = []
		estudiates_con_tipo_ingreso_errado = []
		estudiates_con_iniciado_periodo_id_errado = []
		estudiates_con_region_errada = []

		begin
			csv_text = File.read(file)#.encode('UTF-8', invalid: :replace, replace: '')
			csv = CSV.parse(csv_text, headers: true)
		rescue Exception => e
			errores_generales << "Error al intentar abrir el archivo: #{e}"			
		end


		errores_cabeceras << "'ci'" unless csv.headers.include? 'ci'
		errores_cabeceras << "'nombres'" unless csv.headers.include? 'nombres'
		errores_cabeceras << "'apellidos'" unless csv.headers.include? 'apellidos'
		errores_cabeceras << "'email'" unless csv.headers.include? 'email'

		total_correos_enviados = 0
		total_correos_no_enviados = 0

		if !errores_generales.any? and !errores_cabeceras.any?
			csv.group_by{|row| row['ci']}.values.each do |row|

				begin
					hay_usuario = false

					row = row[0] if !row[0].nil?
					usuario = User.find_or_initialize_by(ci: row['ci'])
					usuario.last_name = row['apellidos']
					usuario.first_name = row['nombres']
					usuario.email = row['email']
					usuario.number_phone = row['telefono']
					usuario.sex = row['sexo']
					nuevo_usuario = usuario.new_record?

					if usuario.save
						hay_usuario = true
						nuevo_usuario ? (total_usuarios_nuevos += 1) : (total_usuarios_actualizados += 1)
					else
						hay_usuario = false
						usuarios_no_agregados << row['ci']
					end

					if hay_usuario
						hay_estudiante = false
						estudiante = Student.find_or_initialize_by(user_id: usuario.id)
						nuevo_estudiante = estudiante.new_record?
						if estudiante.save
							nuevo_estudiante ? (total_estudiantes_nuevos += 1) : (total_estudiantes_actualizados += 1)
							hay_estudiante = true
						else
							estudiantes_no_agregados << estudiante.ci
						end

						if hay_estudiante
							grado = Grade.find_or_initialize_by(student_id: estudiante.id, study_plan_id: study_plan_id)
							grado.admission_type_id = admission_type_id
							grado.registration_status = registration_status
							nuevo_grado = grado.new_record?

							if grado.save
								if nuevo_grado
									total_grados_nuevos += 1
								else
									total_grados_actualizados += 1
								end
							else
								grados_no_agregados << "#{grado.id} Error: (#{grado.errors.full_messages.to_sentence})"
							end
						end
					end
				rescue Exception => e
					errores_generales << "#{row} #{e}" 
				end
			end
		end
		resumen = ""
		resumen +=  "Total de registros a procesar: #{csv.group_by{|row| row['ci']}.count} | "
		resumen += "Total Usuarios Nuevos: #{total_usuarios_nuevos} | "
		resumen += "Total Usuarios Actualizados: #{total_usuarios_actualizados} | "
		resumen += "Total Estudiantes Nuevos: #{total_estudiantes_nuevos} | "
		resumen += "Total Estudiantes Actualizados: #{total_estudiantes_actualizados} | "
		resumen += "Total Grados(Carreras) Nuevos: #{total_grados_nuevos} | "
		resumen += "Total Grados(Carreras) Actualizados: #{total_grados_actualizados} | "
		# resumen += "Total Correos Procesados: #{total_correos_enviados}"

		return [resumen, [estudiantes_no_agregados, usuarios_no_agregados, grados_no_agregados, estudiates_con_plan_errado,estudiates_con_tipo_ingreso_errado, estudiates_con_iniciado_periodo_id_errado, estudiates_con_region_errada, errores_generales, errores_cabeceras]]
	end

	def self.import_teachers file, area_id
		require 'csv'
		errores_cabeceras = []

		begin
			csv_text = File.read(file)#.encode('UTF-8', invalid: :replace, replace: '')
			csv = CSV.parse(csv_text, headers: true)
		rescue Exception => e
			errores_cabeceras << "Error al intentar abrir el archivo: #{e}"			
		end

		errores_cabeceras << "Falta la cabecera 'ci' en el archivo o está mal escrita" unless csv.headers.include? 'ci'
		errores_cabeceras << "Falta la cabecera 'nombres' en el archivo o está mal escrita" unless csv.headers.include? 'nombres'
		errores_cabeceras << "Falta la cabecera 'apellidos' en el archivo o está mal escrita" unless csv.headers.include? 'apellidos'

		if errores_cabeceras.count > 0
			return [0, "Error en las cabaceras del archivo: #{errores_cabeceras.to_sentence}"]
		else		
			total_agregados = 0
			usuarios_existentes = []
			profesores_existentes = []
			usuarios_no_agregados = []
			profes_no_agregados = []
			departamentos_no_encontrados = []
			csv.each do |row|
				begin
					row['ci'].delete! '^0-9'
					row['ci'].strip!
					
					if area = Area.find(area_id)
						if profe = Teacher.where(user_id: row['ci']).first
							profesores_existentes << profe.user_id
							profe.update(area_id: area.id)
						elsif usuario = User.where(ci: row['ci']).first
							usuarios_existentes << usuario.ci
							profe = Teacher.new
							profe.area_id = area.id
							profe.user_id = usuario.ci
							total_agregados += 1 if profe.save
						else
							usuario = User.new
							usuario.ci = row['ci']
							usuario.email = row['email']
							usuario.first_name = row['nombres']
							usuario.last_name = row['apellidos']
							usuario.email = row['email']
							usuario.number_phone = row['telefono']
							if usuario.save
								profe = Teacher.new
								profe.area_id = area.id
								profe.user_id = usuario.id
								if profe.save
									total_agregados += 1
								else
									profes_no_agregados << profe.usuario_id
								end
							else
								usuarios_no_agregados << row['ci']
							end
						end
					end
				end
			end

			resumen = "</br><b>Resumen:</b></br>"
			resumen += "Total Profesores Agregados: <b>#{total_agregados}</b>"
			resumen += "</br>Detalle: #{profesores_existentes.to_sentence.truncate(200)}<hr></hr>"
			resumen += "Total Usuarios Existentes (Se les creó el rol de profesor): <b>#{usuarios_existentes.size}</b>"
			resumen += "</br>Detalle: #{usuarios_existentes.to_sentence.truncate(200)}<hr></hr>"
			resumen += "Total Profesores No Agregados (Se creó el usuario pero no el profesor): <b>#{profes_no_agregados.count}</b>"
			resumen += "</br>Detalle: #{profes_no_agregados.to_sentence.truncate(200)}<hr></hr>"
			resumen += "Total Usuarios No Agregados: <b>#{usuarios_no_agregados.count}</b>"
			resumen += "</br>Detalle: #{usuarios_no_agregados.to_sentence.truncate(200)}<hr></hr>"
			resumen += "Total Departmanetos no enconrtados: <b>#{departamentos_no_encontrados.count}</b>"
			resumen += "</br>Detalle: #{usuarios_no_agregados.to_sentence.truncate(200)}"
				
			return [1, "Proceso de importación completado. #{resumen}"]
		end

	end

	def self.import_subjects file, area_id, qualification_type, modality
		require 'csv'
		errores_cabeceras = []

		begin
			csv_text = File.read(file)#.encode('UTF-8', invalid: :replace, replace: '')
			csv = CSV.parse(csv_text, headers: true)
		rescue Exception => e
			errores_cabeceras << "Error al intentar abrir el archivo: #{e}"			
		end

		p "    HEADERS: #{csv}     ".center(300, '!')
		p "    HEADERS: #{csv.headers}     ".center(300, '!')

		errores_cabeceras << "Falta la cabecera 'id' en el archivo o está mal escrita" unless csv.headers.include? 'id'
		errores_cabeceras << "Falta la cabecera 'nombre' en el archivo o está mal escrita" unless csv.headers.include? 'nombre'

		if errores_cabeceras.any?
			errores_cabeceras = []
			errores_cabeceras << "Falta la cabecera 'id' en el archivo o está mal escrita" unless csv.headers.first.include? 'id'
			errores_cabeceras << "Falta la cabecera 'nombre' en el archivo o está mal escrita" unless csv.headers.first.include? 'nombre'
		end



		if errores_cabeceras.count > 0
			return [0, "Error en las cabaceras del archivo: #{errores_cabeceras.to_sentence}"]
		else		
			errores = []

			total_nuevas = 0
			total_actualizadas = 0

			csv.each do |row|
				begin
		
					row['id'].strip! if row['id']

					if area = Area.find(area_id)

						subject = Subject.find_or_initialize_by(code: row['id'])

						nueva = subject.new_record?
						subject.area_id = area.id
						subject.name = row['nombre']

			
						credit = row['creditos'] ? row['creditos'].to_i : 4
						subject.unit_credits = credit if credit > 0 and credit < 50
						order = row['orden'] ? row['orden'].to_i : 0
						subject.ordinal = order if order >= 0 and order < 13
						tipo_calificacion = row['tipo_calificacion'] ? row['tipo_calificacion'].strip.downcase.to_sym : qualification_type

						tipo_calificacion = :numerica if tipo_calificacion.eql? :numérica
						subject.qualification_type = tipo_calificacion

						subject.modality = row['modalidad'] ? row['modalidad'].strip.downcase.to_sym : modality

						if subject.save
							if nueva
								total_nuevas += 1
							else
								total_actualizadas += 1
							end
						else
							errores << subject.errors.full_messages.to_sentence.truncate(50)
						end
					end
				rescue Exception => e
					errores << "Error General: #{e}"
				end
			end

			resumen = ""
			resumen += "Total Actualizadas: #{total_actualizadas} | "
			resumen += "Total Nuevas: #{total_nuevas} | "

			resumen += "Total Errores: #{errores.count} | " if errores.any?
			resumen += "Tipo de Error: #{errores.uniq.to_sentence}" if errores.any?
			tipo = errores.any? ? 0 : 1
			return [tipo, "Proceso de importación completado. #{resumen}"]
		end

	end


	def self.import_academic_records file, study_plan_id, periodo_id=nil
		require 'csv'

		errores_cabeceras = []
		total_inscritos = 0
		total_existentes = 0
		estudiantes_no_inscritos = []
		total_nuevas_secciones = 0
		total_secciones_existentes = 0
		total_nuevos_inscritos_en_proceso = 0
		total_nuevos_registros_academicos = 0
		secciones_no_creadas = []
		estudiantes_inexistentes = []
		asignaturas_inexistentes = []
		total_calificados = 0
		total_aprobados = 0
		total_aplazados = 0
		total_retirados = 0
		total_no_calificados = 0

		estudiantes_sin_grado = []

		begin
			csv_text = File.read(file).encode('UTF-8', invalid: :replace, replace: '')
			csv = CSV.parse(csv_text, headers: true)
		rescue Exception => e
			errores_cabeceras << "Error al intentar abrir el archivo: #{e}"			
		end

		errores_cabeceras << "Falta la cabecera 'ci' en el archivo" unless csv.headers.include? 'ci'
		errores_cabeceras << "Falta la cabecera 'codigo' en el archivo. Recuerde no incluir acentos en el nombre de la cabecera" unless csv.headers.include? 'codigo'
		errores_cabeceras << "Falta la cabecera 'numero' en el archivo. Recuerde no incluir acentos en el nombre de la cabecera" unless csv.headers.include? 'numero'

		if errores_cabeceras.count > 0
			return [0, "Error en las cabeceras: #{errores_cabeceras.to_sentence}. Corrija el nombre e intente cargar el archivo nuevamente."]
		else

			csv.each_with_index do |row, i|
				begin
					# row = row[0]
					row['ci'].strip!
					row['ci'].delete! '^0-9'

					row['codigo'].strip!
					row['numero'].strip! if row['numero']

					# BUSCAR PERIODO
					if periodo_id.blank?
						p "   SIN PERIODO SELECCIONADO    ".center(200, "=")
						if row['nombre_periodo']

							row['nombre_periodo'].strip!
							row['nombre_periodo'].upcase!

							if period = Period.find_by(name: row['nombre_periodo'])
								periodo_id = period.id
								p "   PERIODO: #{periodo_id}    ".center(200, "=")
							else 
								return [0, "Error: Periodo '#{row['nombre_periodo']}' no se encuentra en los registros. fila (#{i}): [#{row}]. Revise el archivo e inténtelo nuevamente."]
							end

						else
							return [0, "Sin período para la inscripción: #{row}. Por favor revise el archivo e inténtelo nuevamente."]
						end
						periodo_id = row['periodo_id']
					else

						 return [0, "Período por defecto para la inscripción no encontrado."] unless Period.where(id: periodo_id).any? 
					end

					periodo_id_aux = periodo_id

					# BUCAR ASIGNATURA
					unless subject = Subject.where(code: row['codigo']).first
						asignaturas_inexistentes << row['codigo']
						p "   ASIGNATURA INEXISTENTE::::     #{row['codigo']}    ".center(200, "=")
					else
						# BUSCAR PLAN DE ESTUDIO Y ESCUELA:
						plan = StudyPlan.find(study_plan_id)
						if plan.blank?
							return [0, "Plan de Estudio no encontrado."]
						else

							escuela = plan.school
							# BUSCAR O CREAR PROCESO ACADEMICO:
							proceso_academico = AcademicProcess.find_or_create_by(period_id: periodo_id_aux, school_id: escuela.id)

							# BUSCAR O CREAR EL CURSOS (PROGRAMACIÓN):
							curso = Course.find_or_create_by(subject_id: subject.id, academic_process_id: proceso_academico.id)

							# BUSCAR O CREAR SECCIÓN
							s = Section.find_or_initialize_by(code: row['numero'], course_id: curso.id)

							if s.new_record?
								s.capacity = 20 # OJO: SELECT CAPACITY
								s.modality = :nota_final # OJO: SELECT MODALITY
								if s.save
									total_nuevas_secciones += 1 
								else
									secciones_no_creadas << row.to_hash
								end

							else
								total_secciones_existentes += 1
							end

							# BUSCAR ESTUDIANTE
							estu = (Student.by_ci row['ci']).first
							if estu.nil?
								estudiantes_inexistentes << row['ci']
							else
								# BUSCAR GRADO
								unless grado = estu.grades.where(study_plan_id: study_plan_id).first
									estudiantes_sin_grado << estu.id
								else
									# BUSCAR O CREAR INSCRIPCIÓN PROCESO ACADEMICO:

									inscrip_proceso_academico = EnrollAcademicProcesses.find_or_initialize_by(academic_process_id: proceso_academico.id, grade_id: grado.id)

									if inscrip_proceso_academico.new_record?
										inscrip_proceso_academico.enroll_status = :confirmado
										inscrip_proceso_academico.permanence_status = :regular
										
										total_nuevos_inscritos_en_proceso += 1 if inscrip_proceso_academico.save
									end

									# BUSCAR O CREAR REGISTRO ACADEMICO

									inscrip = AcademicRecord.find_or_initialize_by(section_id: s.id, enroll_academic_process_id: inscrip_proceso_academico.id)


									# CALIFICAR:
									if row['nota'] and !row['nota'].blank?
										row['nota'].strip!
										inscrip.calificar row['nota']
										if inscrip.retirado?
											total_retirados += 1
										elsif inscrip.aprobado?
											total_aprobados += 1
										else
											total_aplazados += 1
										end
									end

									nuevo = inscrip.new_record?

									if inscrip.save!
										total_nuevos_registros_academicos += 1 if nuevo
										total_inscritos += 1
										total_calificados += 1
									else
										estudiantes_no_inscritos << row['ci']
										total_no_calificados += 1
									end
								end
							end
						end						
					end
				rescue Exception => e
					# => OJO AYUDA EN EL ENTORNO DE DESARROLLO COLOCANDO EL BACKTRACE VISIBLE
					backtrace = (Rails.root.to_s.include? 'localhost') ? "#{e.backtrace.first}" : ''

					return [0, "Error excepcional con el registro #{row.to_hash}: #{e.message} #{backtrace}. #{self.resumen total_inscritos, total_existentes, estudiantes_no_inscritos, total_nuevas_secciones, secciones_no_creadas, estudiantes_inexistentes, asignaturas_inexistentes, total_calificados, total_no_calificados, total_aprobados, total_aplazados, total_retirados, periodo_id, estudiantes_sin_grado, total_nuevos_inscritos_en_proceso, total_nuevos_registros_academicos }"]

				end
			end
			return [1, "Resumen procesos de migración: #{self.resumen total_inscritos, total_existentes, estudiantes_no_inscritos, total_nuevas_secciones, secciones_no_creadas, estudiantes_inexistentes, asignaturas_inexistentes, total_calificados, total_no_calificados, total_aprobados, total_aplazados, total_retirados,periodo_id, estudiantes_sin_grado, total_nuevos_inscritos_en_proceso, total_nuevos_registros_academicos}"]
		end

	end


	def self.importar_estudiantes_e_inscripciones file, periodo_id
		require 'csv'

		csv_text = File.read(file)
		total_inscritos = 0
		total_existentes = 0
		estudiantes_no_inscritos = []
		total_nuevas_secciones = 0
		secciones_no_creadas = []
		estudiantes_inexistentes = []
		asignaturas_inexistentes = []
		total_calificados = 0
		total_aprobados = 0
		total_aplazados = 0
		total_retirados = 0
		total_no_calificados = 0		
		p "RESULTADO".center(200, "=")
		rows = CSV.parse(csv_text, headers: true, encoding: 'iso-8859-1:utf-8')

		rows.group_by{|row| row[2]}.values.each do |asig|
			id_uxxi = limpiar_cadena asig[0][1]
			if a = Asignatura.where(id_uxxi: id_uxxi).first
				asig.group_by{|sec| sec[2]}.each do |seccion|
					seccion_id = seccion[0]

					unless s = Seccion.where(numero: seccion_id, periodo_id: periodo_id, asignatura_id: id_uxxi).limit(1).first
					
						total_nuevas_secciones += 1 if s = Seccion.create!(numero: seccion_id, periodo_id: periodo_id, asignatura_id: id_uxxi, tipo_seccion_id: 'NF')
					end

					if s
						seccion[1].each do |reg|

							if Estudiante.where(usuario_id: reg.field(0)).count <= 0

								estudiantes_inexistentes << reg.field(0)

							else
								inscrip = s.inscripcionsecciones.where(estudiante_id: reg.field(0)).first
								
								unless inscrip
										inscrip = Inscripcionseccion.new
										inscrip.seccion_id = s.id
										inscrip.estudiante_id = reg.field(0)
										
									if inscrip.save
										total_inscritos += 1
									else
										estudiantes_no_inscritos << reg.field(0)
									end
								else
									total_existentes += 1
								end

								# CALIFICAR:
								if reg.field(3) and ! reg.field(3).blank?
									reg.field(3).strip!
									if reg.field(3).eql? 'RT'
										inscrip.estado = :retirado
										inscrip.tipo_calificacion_id = TipoCalificacion::FINAL 
									elsif inscrip.asignatura and inscrip.asignatura.absoluta?
										if reg.field(3).eql? 'A'
											inscrip.estado = :aprobado
										else
											inscrip.estado = :aplazado
										end
										inscrip.tipo_calificacion_id = TipoCalificacion::FINAL
									else
										inscrip.calificacion_final = reg.field(3)
										
										if inscrip.calificacion_final >= 10
											inscrip.estado = :aprobado
										else
											if inscrip.calificacion_final == 0
												inscrip.tipo_calificacion_id = TipoCalificacion::PI 
											else
												inscrip.tipo_calificacion_id = TipoCalificacion::FINAL 
											end
											inscrip.estado = :aplazado
										end
									end

									if inscrip.save
										total_calificados += 1
										if inscrip.retirado?
											total_retirados += 1
										elsif inscrip.aprobado?
											total_aprobados += 1
										else
											total_aplazados += 1
										end
									else
										total_no_calificados += 1
									end
								end
							end







						end

					else
						secciones_no_creadas << row.to_hash
					end						



				end 
			else
				asignaturas_inexistentes << id_uxxi
			end
		end
  		# puts [group.first['ID'], group.map{|r| r['COMMENT']} * ' '] * ' | '
		
		# rows.each do |row|
		# 	begin
		# 		row = limpiar_fila row
		# 		#p self.separar_cadena(row.field(1))
		# 	rescue Exception => e
		# 		return "Error excepcional: #{e.to_sentence}"
		# 	end
		# end
		p "=".center(200, "=")
	end

	private


	def self.resumen inscritos, existentes, no_inscritos, nuevas_secciones, secciones_no_creadas, estudiantes_inexistentes, asignaturas_inexistentes, total_calificados, total_no_calificados, total_aprobados, total_aplazados, total_retirados, periodo_id, estudiantes_sin_grado,  total_nuevos_inscritos_en_proceso= 0, total_nuevos_registros_academicos=0
		
		aux = ""
		aux = "Período: #{periodo_id} | 
			Total Nuevos Inscritos: #{inscritos} | 
			Total Existentes: #{existentes} | 
			Total Nuevas Secciones: #{nuevas_secciones} | 
			Total Nuevos Inscritos en Proceso: #{total_nuevos_inscritos_en_proceso} | 
			Total Nuevos Registos Académicos: #{total_nuevos_registros_academicos} | 
			Total Secciones No Creadas: #{secciones_no_creadas.count} | 
			Total Asignaturas Inexistentes: #{asignaturas_inexistentes.uniq.count} | 
			Detalle últimos 50: #{asignaturas_inexistentes.uniq.to_sentence}
			No registrados en la escuela: #{estudiantes_sin_grado.uniq[0..50].to_sentence} | 
			Total Estudiantes Inexistentes: #{estudiantes_inexistentes.uniq.count} | 
			Detalle últimos 50: #{estudiantes_inexistentes.uniq[0..50].to_sentence} | "

		if total_calificados and total_calificados.to_i > 0
			aux += "Calificaciones:"
			aux += "Total Estudiantes Calificados: #{total_calificados} | "
			aux += "Total Estudiantes Aprobados: #{total_aprobados} | "
			aux += "Total Estudiantes Aplazados: #{total_aplazados} | "
			aux += "Total Estudiantes Retirados: #{total_retirados} | "
			aux += "Total Estudiantes No Calificados: #{total_no_calificados} | "

		end
		return aux
	end

	def crear_usuario usuario_params
		hay_usuario = false
		if usuario = Usuario.where(ci: usuario_params[:ci]).limit(1).first
			hay_usuario = true
		else
			usuario = Usuario.new
			usuario.ci = usuario_params[:ci]
			usuario.password = usuario_params[:ci]
			usuario.nombres = usuario_params[:nombres]
			usuario.apellidos = usuario_params[:apellidos]
			
			hay_usuario = true if usuario.save
		end

		hay_usuario ? usuario : false

	end



	def self.separar_cadena cadena = nil
		if cadena.blank?
			return [nil,nil]
		else
			cadena = limpiar_cadena cadena
			a = cadena.split(" ")
			t = (a.count)-1
			i = (a.count/2)-1
			i = 0 if i < 0  

			return [a[0..i].join(" "),a[i+1..t].join(" ")]
		end
	end

	def self.limpiar_fila row
		row.field(0).delete! '^0-9'
		row.fields.each{|r| r = limpiar_cadena(r) if r}
		# row.field(1) = limpiar_cadena(row.field(1))
		# row.field(2) = limpiar_cadena row.field(2) if row.field(2)
		# row.field(3) = limpiar_cadena row.field(3) if row.field(3)
		# row.field(4) = limpiar_cadena row.field(4) if row.field(4)

		return row
	end

	def self.limpiar_cadena cadena
		cadena.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
		cadena.strip!
		return cadena
	end




end