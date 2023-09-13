pretty_value do
  if bindings[:object].process_before
    enrollment_days = bindings[:object].enrollment_days
    grades_without_appointment = bindings[:object].readys_to_enrollment_day

    bindings[:view].content_tag(:table, {class: 'table table-sm table-striped table-hover'}) do 
      bindings[:view].content_tag(:tr) do
        bindings[:view].content_tag(:th, 'ID').concat(bindings[:view].content_tag(:th, 'Nombre')).concat(bindings[:view].content_tag(:tr) do
          bindings[:view].content_tag(:td, bindings[:object].id).concat(bindings[:view].content_tag(:td, bindings[:object].name)) 
        end)
      end
    end 

    # bindings[:view].render(partial: "/enrollment_days/index", locals: {enrollment_days: enrollment_days, grades_without_appointment: grades_without_appointment, academic_process: bindings[:object]})

  else
    bindings[:view].content_tag(:p, 'Sin proceso academico anterio vinculado. Para habilitar el sistema de Cita Horaria en este proceso académico, por favor edítelo y agregue un proceso anteriór', {class: 'alert alert-warning'})
  end
end


- if false
  .toast{"aria-atomic" => "true", "aria-live" => "assertive", :role => "alert", autohide: false}
    .toast-header
      %img.rounded.me-2{:alt => "...", :src => "..."}/
      %strong.me-auto Bootstrap
      %small 11 mins ago
      %button.btn-close{"aria-label" => "Close", "data-bs-dismiss" => "toast", :type => "button"}
    .toast-body
      Hello, world! This is a toast message.


- if false #current_user.eql? @student.user and grade and grade.reportepago.nil? and grade.asignado? and !@grado.enroll_academic_process.any?
  - # REPORTE DE PAGO DE LA ESCUELA
  - # 
  = # render template: 'payment_reports/new'que contenga lo de abajo 👇🏽
  - reportable = grado
  - payment_report = PaymentReport.new
  - content = render partial: "/payment_reports/form"
  = render partial: '/layouts/scaffold-modal', locals: {id_modal: "paymentReportGrade#{@grado.id}", content: content, title: 'Reportar Pago a la Facultad de Ingreso a Escuela'}

  = link_to '#', onclick: "$('#paymentReportGrade#{grado.id}').modal()", class: 'm-3 btn btn-success' do
    = glyph 'plus'
    = "Reportar Pago Ingreso a #{grade.school.code}"


