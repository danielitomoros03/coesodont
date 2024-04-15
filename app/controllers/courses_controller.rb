class CoursesController < ApplicationController
  before_action :set_course, only: %i[update]

  def create
    begin
      respond_to do |format|
        course = Course.new(course_params)
        if course.save
          new_section = ApplicationController.helpers.button_add_section(course.id)
          offer_subject = view_context.render partial: '/academic_processes/form_offer_subject', locals: {course: course}

          # p "   CURSO: <#{new_section}>.   ".center(500, "#")
          format.json {render json: {data: "¡Curso activado para el período #{course.academic_process.period_name}!", status: :success, new_section: new_section, type: :create, offer_subject: offer_subject} }
        else
          format.json { render json: {data: course.errors, status: :unprocessable_entity} }
        end
      end
      
    rescue Exception => e
      format.json { render json: {data: e, status: :unprocessable_entity} }
    end
  end

  # UPDATE
  def update
    respond_to do |format|
      if @course.update(course_params)
        msg = @course.offer? ? "Curso ofertado para inscripción #{@course.academic_process.period.name}" : "Curso oculto para inscripción #{@course.academic_process.period.name}"
        format.json { render json: {data: msg, status: :success, type: :update} }
      else
        format.json {render json: {data: "¡Error al intentar ofertar/ocultar la asignatura para el período #{period_name}!", status: :unprocessable_entity} }
      end
    end
  end

  # DELETE /courses/1 or /courses/1.json
  def destroy
    begin
      course = Course.find_by(course_params)
      period_name = course.academic_process.period_name

      respond_to do |format|
        if course.destroy
          format.json {render json: {data: "¡Curso desactivado para el período #{period_name}!", status: :success, type: :destroy} }
        else
          format.json {render json: {data: "¡Error al intentar desactivar la asignatura para el período #{period_name}!", status: :unprocessable_entity} }
        end
      end
    rescue Exception => e
      respond_to do |format|
        format.json {render json: {data: e, status: :unprocessable_entity} }
      end
    end
  end

  private
    # Only allow a list of trusted parameters through.
    def set_course
      @course = Course.find(params[:id])
    end    
    def course_params
      params.require(:course).permit(:academic_process_id, :subject_id, :offer_as_pci, :offer)
    end
end
