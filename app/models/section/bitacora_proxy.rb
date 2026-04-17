class Section
  class BitacoraProxy
    IGNORED_CHANGE_KEYS = %w[created_at updated_at].freeze
    AR_STATUS_LABELS = {
      0 => 'Sin calificar',
      1 => 'Aprobado',
      2 => 'Aplazado',
      3 => 'Retirado',
      4 => 'Perdida por inasistencia'
    }.freeze
    Q_TYPE_LABELS = {
      0 => 'Final',
      1 => 'Diferido',
      2 => 'Reparación'
    }.freeze

    def initialize(version, user_lookup: {}, item_cache: {})
      @version = version
      @user_lookup = user_lookup
      @item_cache = item_cache
    end

    def created_at
      @version.created_at
    end

    def table
      @version.item_type
    end

    def item
      @version.item_id
    end

    def item_type
      @version.item_type
    end

    def event_kind
      raw = @version.event.to_s
      case raw
      when 'create' then :creacion
      when 'update' then :modificacion
      when 'destroy' then :eliminacion
      else
        downcased = raw.downcase
        if downcased.match?(/elimina|destruid|borrad/)
          :eliminacion
        elsif downcased.match?(/actualiz|cambió|cambio|modifica|calificad/)
          :modificacion
        elsif downcased.match?(/registrad|cread|nuev/)
          :creacion
        else
          :otro
        end
      end
    end

    def message
      @version.event.presence || '-'
    end

    def event_description
      kind = {
        creacion: 'Creación',
        modificacion: 'Modificación',
        eliminacion: 'Eliminación',
        otro: @version.event.to_s.titleize
      }[event_kind]

      [kind, custom_event].compact.reject(&:blank?).join(' — ')
    end

    def custom_event
      @version.event.to_s unless %w[create update destroy].include?(@version.event)
    end

    def username
      user&.reverse_name || fallback_username
    end

    def user
      return nil if @version.whodunnit.blank?

      @user_lookup[@version.whodunnit.to_s]
    end

    def fallback_username
      whodunnit = @version.whodunnit
      whodunnit.presence || 'Sistema'
    end

    def student_ci
      student&.user&.ci
    end

    def student_name
      student&.user&.reverse_name
    end

    def student
      case item_type
      when 'Qualification'
        record&.academic_record&.student
      when 'AcademicRecord'
        record&.student
      end
    end

    def record
      @item_cache.dig(item_type, @version.item_id)
    end

    def qualification_type
      return nil unless item_type == 'Qualification' && record

      I18n.t(record.type_q, default: record.type_q.to_s.titleize)
    end

    def changes_summary
      data = parsed_changes
      return nil if data.blank?

      data.reject { |k, _| IGNORED_CHANGE_KEYS.include?(k.to_s) }.map do |field, values|
        label = humanize_field(field)
        old_value, new_value = Array(values)
        "#{label}: #{format_value(old_value)} → #{format_value(new_value)}"
      end.join(' | ')
    end

    def parsed_changes
      raw = @version.object_changes
      return {} if raw.blank?

      if raw.is_a?(String)
        begin
          YAML.safe_load(raw, permitted_classes: [Time, Date, Symbol, BigDecimal, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])
        rescue StandardError
          {}
        end
      else
        raw
      end
    end

    def humanize_field(field)
      I18n.t("activerecord.attributes.#{item_type.underscore}.#{field}", default: field.to_s.humanize)
    end

    def format_value(value)
      case value
      when nil then '∅'
      when true then 'Sí'
      when false then 'No'
      when Time, Date, ActiveSupport::TimeWithZone then I18n.l(value, format: :short)
      else value.to_s
      end
    end

    def badge_class
      case event_kind
      when :creacion then 'bg-success'
      when :modificacion then 'bg-info'
      when :eliminacion then 'bg-danger'
      else 'bg-secondary'
      end
    end

    def item_label
      case item_type
      when 'Qualification' then 'Calificación'
      when 'AcademicRecord' then 'Registro Académico'
      when 'Section' then 'Sección'
      when 'SectionTeacher' then 'Profesor'
      else item_type
      end
    end

    def paper_trail_event
      @version.event
    end

    def summary_title
      case item_type
      when 'Qualification' then qualification_summary_title
      when 'AcademicRecord' then academic_record_summary_title
      when 'Section' then section_summary_title
      when 'SectionTeacher' then section_teacher_summary_title
      else @version.event.to_s.titleize
      end
    end

    def section_teacher_summary_title
      teacher_name = section_teacher_name
      case event_kind
      when :creacion then teacher_name ? "Profesor asignado: #{teacher_name}" : 'Profesor asignado'
      when :eliminacion then teacher_name ? "Profesor removido: #{teacher_name}" : 'Profesor removido'
      else 'Cambio de profesor'
      end
    end

    def section_teacher_name
      if record&.teacher&.user
        record.teacher.user.reverse_name rescue "#{record.teacher.user.last_name}, #{record.teacher.user.first_name}"
      else
        changes = parsed_changes
        teacher_id = Array(changes['teacher_id']).last || Array(changes['teacher_id']).first
        return nil unless teacher_id

        teacher = Teacher.unscoped.includes(:user).find_by(id: teacher_id)
        teacher&.user&.reverse_name rescue nil
      end
    end

    def summary_detail
      return nil if %w[AcademicRecord Qualification].include?(item_type)
      changes_summary
    end

    def qualification_summary_title
      changes = parsed_changes
      old_v, new_v = Array(changes['value'])

      case event_kind
      when :creacion
        new_v.present? ? "Calificada con #{format_grade(new_v)}" : 'Calificación registrada'
      when :eliminacion
        'Calificación eliminada'
      when :modificacion
        if changes.key?('value')
          if old_v.nil? || old_v.to_s.strip.empty?
            "Calificada con #{format_grade(new_v)}"
          elsif new_v.nil? || new_v.to_s.strip.empty?
            "Calificación removida (era #{format_grade(old_v)})"
          else
            "Calificación modificada: #{format_grade(old_v)} → #{format_grade(new_v)}"
          end
        else
          'Calificación modificada'
        end
      else
        @version.event.to_s.titleize
      end
    end

    def format_grade(value)
      return '∅' if value.nil?
      str = value.to_s
      return 'PI' if str.match?(/\A0(\.0+)?\z/)
      str.match?(/\A-?\d+(\.\d+)?\z/) ? str.sub(/\.0+\z/, '') : str
    end

    def academic_record_summary_title
      changes = parsed_changes
      _old_s, new_s = Array(changes['status'])
      case event_kind
      when :eliminacion then 'Inscripción eliminada'
      when :modificacion
        case new_s
        when 3 then 'Retirada'
        when 4 then 'Perdida por inasistencia (PI)'
        else 'Registro académico modificado'
        end
      else
        @version.event.to_s.titleize
      end
    end

    def section_summary_title
      changes = parsed_changes
      case event_kind
      when :creacion then 'Sección creada'
      when :eliminacion then 'Sección eliminada'
      when :modificacion
        if changes.keys.map(&:to_s).include?('qualified')
          _old_q, new_q = Array(changes['qualified'])
          (new_q ? 'Sección marcada como calificada' : 'Sección desmarcada de calificada')
        else
          'Sección modificada'
        end
      else
        @version.event.to_s.titleize
      end
    end

    def summary_badge_class
      case item_type
      when 'Qualification' then 'bg-primary'
      when 'AcademicRecord' then academic_record_badge
      when 'Section' then 'bg-secondary'
      when 'SectionTeacher' then 'bg-info text-dark'
      else 'bg-secondary'
      end
    end

    def academic_record_badge
      changes = parsed_changes
      return 'bg-info' unless changes.key?('status')
      _, new_s = Array(changes['status'])
      case new_s
      when 3 then 'bg-danger'
      when 1 then 'bg-success'
      when 2 then 'bg-warning text-dark'
      when 4 then 'bg-dark'
      else 'bg-info'
      end
    end

    def short_date
      return nil unless created_at
      local = created_at.in_time_zone('Caracas') rescue created_at
      wday = %w[dom lun mar mié jue vie sáb][local.wday]
      "#{wday} #{local.strftime('%d/%m/%Y %H:%M')}"
    end

    def ip
      @version.try(:ip)
    end

    def user_agent
      @version.try(:user_agent)
    end

    def device_label
      UserAgentParser.call(user_agent)
    end
  end
end
