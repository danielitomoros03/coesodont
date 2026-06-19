class RegulationStreamsController < ApplicationController
  include ActionController::Live

  # GET /academic_processes/:id/run_regulation_stream?id_return=:id_return
  # Recalcula el reglamento (art. 3/6/7, desertor, etc.) + eficiencia y promedios de cada
  # inscripción del proceso, emitiendo el avance por Server-Sent Events para alimentar la
  # barra de progreso. Es el mismo trabajo que antes hacía run_regulation, ahora con streaming.
  def show
    # Evita que el middleware de sesión reescriba/rote la cookie durante el streaming
    # (de lo contrario ActionController::Live + Devise deslogue al usuario).
    request.session_options[:skip] = true

    academic_process = AcademicProcess.find(params[:id])

    # Mismo patrón anti-buffering que el export xlsx (ETag/Last-Modified/Content-Length),
    # imprescindible para que los eventos fluyan en vivo y no se acumulen hasta el final.
    response.headers.delete('Content-Length')
    response.headers['Content-Type']      = 'text/event-stream'
    response.headers['Cache-Control']     = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no' # desactiva el buffering de Nginx (Dokku)
    response.headers['ETag']              = '0'
    response.headers['Last-Modified']     = '0'
    sse = ActionController::Live::SSE.new(response.stream, retry: 1000)

    scope = academic_process.enroll_academic_processes.includes(:grade, :academic_records, :period)
    total = scope.count
    procesados = 0
    actualizados = 0
    errores = 0
    last_percent = -1

    EnrollmentDay.destroy_all

    scope.find_each do |iep|
      grade = iep.grade
      # Recalcular el reglamento, no copiar el valor viejo almacenado
      nuevo_status = iep.get_regulation

      ok = iep.update(permanence_status: nuevo_status, efficiency: iep.calculate_efficiency, simple_average: iep.calculate_average, weighted_average: iep.calculate_weighted_average)

      ok &&= if iep.is_the_last_enroll_of_grade?
               grade.update(current_permanence_status: nuevo_status, efficiency: grade.calculate_efficiency, weighted_average: grade.calculate_weighted_average, simple_average: grade.calculate_average)
             else
               grade.update(efficiency: grade.calculate_efficiency, weighted_average: grade.calculate_weighted_average, simple_average: grade.calculate_average)
             end

      ok ? actualizados += 1 : errores += 1
      procesados += 1

      percent = total.zero? ? 100 : (procesados * 100 / total)
      next if percent == last_percent

      last_percent = percent
      sse.write({ procesados: procesados, total: total, percent: percent, actualizados: actualizados, errores: errores }, event: 'progress')
    end

    sse.write({ actualizados: actualizados, errores: errores, total: total, return_url: "/admin/academic_process/#{params[:id_return]}/enrollment_day" }, event: 'done')
  rescue ActionController::Live::ClientDisconnected
    # El usuario cerró/recargó la ventana: el cálculo se detiene en seco.
  rescue StandardError => e
    begin
      sse&.write({ message: e.message }, event: 'fail')
    rescue StandardError
      nil
    end
  ensure
    sse&.close
  end
end
