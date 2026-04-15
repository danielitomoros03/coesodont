class Section
  class StudentRowProxy
    STATUS_BADGE = {
      'aprobado' => 'bg-success',
      'aplazado' => 'bg-warning text-dark',
      'retirado' => 'bg-secondary',
      'perdida_por_inasistencia' => 'bg-danger',
      'sin_calificar' => 'bg-light text-dark border'
    }.freeze

    def initialize(academic_record, latest_version: nil, user_lookup: {})
      @ar = academic_record
      @version = latest_version
      @user_lookup = user_lookup
    end

    def created_at
      @version&.created_at || @ar.updated_at
    end

    def short_date
      return nil unless created_at
      local = created_at.in_time_zone('Caracas') rescue created_at
      wday = %w[dom lun mar mié jue vie sáb][local.wday]
      "#{wday} #{local.strftime('%d/%m/%Y %H:%M')}"
    end

    def student_ci
      @ar.user&.ci
    end

    def student_name
      @ar.user&.reverse_name rescue "#{@ar.user&.last_name}, #{@ar.user&.first_name}"
    end

    def item_label
      'Estudiante'
    end

    def summary_title
      case @ar.status.to_s
      when 'retirado' then 'Retirada'
      when 'perdida_por_inasistencia' then 'Perdida por inasistencia (PI)'
      when 'aprobado' then grade_label ? "Aprobado (#{grade_label})" : 'Aprobado'
      when 'aplazado' then grade_label ? "Aplazado (#{grade_label})" : 'Aplazado'
      when 'sin_calificar'
        grade_label ? "Calificada con #{grade_label}" : 'Sin calificar'
      else @ar.status.to_s.humanize
      end
    end

    def summary_detail
      nil
    end

    def summary_badge_class
      STATUS_BADGE[@ar.status.to_s] || 'bg-secondary'
    end

    def username
      return user_label_from_version if @version
      'Sistema'
    end

    def user_label_from_version
      whodunnit = @version.whodunnit
      return 'Sistema' if whodunnit.blank?
      user = @user_lookup[whodunnit.to_s] if whodunnit.to_s.match?(/\A\d+\z/)
      user&.ci_fullname || whodunnit.to_s
    end

    def ip
      @version&.try(:ip)
    end

    def user_agent
      @version&.try(:user_agent)
    end

    def device_label
      UserAgentParser.call(user_agent)
    end

    private

    def grade_label
      return nil unless qualification&.value
      str = qualification.value.to_s
      return 'PI' if str.match?(/\A0(\.0+)?\z/)
      str.match?(/\A-?\d+(\.\d+)?\z/) ? str.sub(/\.0+\z/, '') : str
    end

    def qualification
      @qualification ||= begin
        quals = @ar.qualifications.to_a
        quals.find { |q| q.type_q.to_s == 'final' } || quals.first
      end
    end
  end
end
