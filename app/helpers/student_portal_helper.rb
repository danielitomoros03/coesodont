module StudentPortalHelper
  def iniciales(user)
    [user.first_name, user.last_name].map { |n| n.to_s.strip[0] }.join.upcase
  end

  def ci_formateada(user)
    prefijo = user.student&.nacionality == 'Extranjero/a' ? 'E' : 'V'
    "C.I. #{prefijo}-#{number_with_delimiter(user.ci, delimiter: '.')}"
  end

  # Title case para nombres de asignatura (vienen en MAYÚSCULAS de la BD):
  # respeta números romanos y baja los conectores.
  def nombre_asignatura(nombre)
    nombre.titleize
          .gsub(/\b[ivx]{1,4}\b/i, &:upcase)
          .gsub(/\b(De|Del|La|Las|El|Los|Y|E|En|Para|A)\b/, &:downcase)
  end

  def numero_portal(valor, decimales = 2)
    number_with_precision(valor.to_f, precision: decimales, separator: ',', delimiter: '.')
  end

  def enlace_descarga(texto, ruta)
    link_to texto, ruta, class: 'btn-portal btn-portal--secundario btn-portal--sm',
                         target: '_blank', rel: 'noopener noreferrer'
  end

  def chip_portal(texto, tono = :neutro)
    content_tag :span, texto, class: "chip chip--#{tono}"
  end

  def permanencia_texto(status)
    status.to_s.tr('_', ' ').sub(/\Aarticulo(\d)/, 'artículo \1').capitalize
  end

  def tono_permanencia(status)
    case status
    when 'regular', 'egresado', 'egresado_doble_titulo', 'via_de_gracia' then :aprobado
    when 'nuevo', 'reincorporado', 'intercambio' then :curso
    when 'articulo3' then :alerta
    when 'articulo6', 'articulo7', 'desertor', 'permiso_para_no_cursar' then :reprobado
    else :neutro
    end
  end

  # Teselas de la celosía: obligatorias del pensum + electivas/optativas ya
  # cursadas o en curso (la oferta electiva completa inflaría el "por cursar").
  def celosia_teselas(grade, en_curso_ids)
    aprobadas_ids = grade.subjects_approved_ids
    subjects = grade.school.subjects.where(active: true).order(:ordinal, :code)
    subjects.filter_map do |subject|
      estado = if aprobadas_ids.include?(subject.id)
                 :aprobada
               elsif en_curso_ids.include?(subject.id)
                 :curso
               else
                 :resta
               end
      next if estado == :resta && !subject.obligatoria?

      [subject, estado]
    end
  end

  # Semestre predominante entre las asignaturas en curso
  def semestre_en_curso(records_en_curso)
    ordinales = records_en_curso.map { |ar| ar.subject.ordinal }.reject(&:zero?)
    ordinales.tally.max_by { |ordinal, veces| [veces, ordinal] }&.first
  end

  SEMESTRES = %w[Primer Segundo Tercer Cuarto Quinto Sexto Séptimo Octavo Noveno Décimo].freeze

  def semestre_palabra(ordinal)
    nombre = SEMESTRES[ordinal - 1]
    nombre ? "#{nombre} semestre" : "Semestre #{ordinal}"
  end

  def hora_chip(schedule)
    "#{schedule.day[0, 2]} #{formato_hora(schedule.starttime)}–#{formato_hora(schedule.endtime)}"
  end

  def formato_hora(tiempo)
    tiempo.strftime('%-H:%M')
  end

  # Retícula del horario semanal a partir de los AcademicRecords en curso.
  # Devuelve nil sin horarios; si no, { dias:, hora_min:, hora_max:, bloques: }
  # con filas CSS = hora - hora_min + 2 (la fila 1 es la cabecera de días).
  def horario_semanal(records)
    pares = records.flat_map { |ar| ar.section.schedules.map { |s| [ar.subject, s] } }
    return nil if pares.empty?

    dias = Schedule.days.keys
    dias = dias.first(pares.any? { |_, s| s.day == 'Sábado' } ? 6 : 5)
    hora_min = pares.map { |_, s| s.starttime.hour }.min - 1
    hora_max = pares.map { |_, s| s.endtime.hour + (s.endtime.min.positive? ? 1 : 0) }.max
    bloques = pares.filter_map do |subject, s|
      col = dias.index(s.day)
      next unless col

      { columna: col + 2,
        fila_inicio: s.starttime.hour - hora_min + 2,
        fila_fin: s.endtime.hour + (s.endtime.min.positive? ? 1 : 0) - hora_min + 2,
        nombre: subject.name, aula: s.section.classroom }
    end
    { dias: dias, hora_min: hora_min, hora_max: hora_max, bloques: bloques }
  end

  # Numera cronológicamente las veces que se inscribió cada asignatura,
  # para marcar "2.ª inscripción" en el historial. Devuelve {ar.id => n}.
  def intentos_por_registro(eaps)
    contador = Hash.new(0)
    eaps.sort_by { |eap| [eap.academic_process.period.year, eap.academic_process.period.period_type_id] }
        .each_with_object({}) do |eap, mapa|
      eap.academic_records.each do |ar|
        contador[ar.subject.id] += 1
        mapa[ar.id] = contador[ar.subject.id]
      end
    end
  end

  ESTADOS_RECORD = { 'sin_calificar' => 'Sin calificar', 'aprobado' => 'Aprobada', 'aplazado' => 'Aplazada',
                     'retirado' => 'Retirada', 'perdida_por_inasistencia' => 'PI' }.freeze

  def estado_record(academic_record)
    ESTADOS_RECORD[academic_record.status] || academic_record.status.titleize
  end

  ESTADOS_INSCRIPCION = { 'confirmado' => %w[Confirmada aprobado], 'preinscrito' => %w[Preinscrita curso],
                          'reservado' => %w[Reservada alerta] }.freeze

  def chip_inscripcion(enroll_academic_process)
    estado = enroll_academic_process.enroll_status
    texto, tono = ESTADOS_INSCRIPCION[estado] || [estado.titleize, 'neutro']
    chip_portal(texto, tono)
  end

  # Tono del chip según el status de un AcademicRecord
  def tono_academic_record(academic_record)
    case academic_record.status
    when 'aprobado' then :aprobado
    when 'aplazado' then :reprobado
    when 'retirado', 'perdida_por_inasistencia' then :retirado
    else :curso
    end
  end
end
