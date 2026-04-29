class AcademicRecordsController < ApplicationController
  before_action :set_academic_record, only: %i[ show edit update destroy ]
  before_action :ensure_can_manage_academic_records!, only: %i[ create ]

  # GET /academic_records or /academic_records.json
  def index
    @academic_records = AcademicRecord.all
  end

  # GET /academic_records/1 or /academic_records/1.json
  def show
  end

  # GET /academic_records/new
  def new
    @academic_record = AcademicRecord.new
    # @grade = Grade.find params[:grade_id]
    # @academic_process = AcademicProcess.find params[:academic_process_id]

    # @school = @grade.school
  end

  # GET /academic_records/1/edit
  def edit
  end

  # POST /academic_records or /academic_records.json
  def create
    @academic_record = AcademicRecord.new(academic_record_params)

    enroll_academic_process = @academic_record.enroll_academic_process
    unless enroll_academic_process
      flash[:danger] = 'Sin inscripción en sistema'
      return redirect_back(fallback_location: root_path)
    end

    subject = Subject.find_by(id: params[:course][:subject_id])
    unless subject
      flash[:danger] = 'Asignatura no encontrada'
      return redirect_back(fallback_location: root_path)
    end

    academic_process = @academic_record.academic_process
    unless academic_process
      flash[:danger] = 'Periodo no encontrado'
      return redirect_back(fallback_location: root_path)
    end

    ActiveRecord::Base.transaction do
      course = Course.find_or_create_by!(subject_id: subject.id, academic_process_id: academic_process.id)

      section = Section.find_or_initialize_by(course_id: course.id, code: params[:section_code])
      if section.new_record?
        section.capacity = 30
        section.modality = if params[:ee]
                             :equivalencia_externa
                           elsif params[:ei]
                             :equivalencia_interna
                           else
                             :nota_final
                           end
      end
      section.save!
      @academic_record.section = section

      if subject.absoluta?
        @academic_record.status = if params[:approved]
                                    :aprobado
                                  elsif params[:pi]
                                    :perdida_por_inasistencia
                                  elsif params[:rt]
                                    :retirado
                                  else
                                    :aplazado
                                  end
      elsif params[:pi]
        @academic_record.status = :perdida_por_inasistencia
      elsif params[:rt]
        @academic_record.status = :retirado
      end

      @academic_record.save!
      flash[:success] = 'Se guardó el historial '

      if subject.numerica? && @academic_record.sin_calificar? && params[:qualifications].present? && params[:qualifications][:value].present?
        qa = @academic_record.qualifications.new(type_q: params[:qualifications][:type_q], value: params[:qualifications][:value])
        if qa.save
          flash[:success] += '¡Calificación cargada!'
        else
          flash[:warning] = "Error al intentar guardar la calificación: #{qa.errors.full_messages.to_sentence}"
        end
      elsif subject.numerica? && @academic_record.sin_calificar?
        flash[:warning] = 'No se especificó la calificación'
      end
    end

    redirect_back fallback_location: root_path

  rescue StandardError => e
    flash[:danger] = "Error al intentar guardar: #{e.message}"
    redirect_back fallback_location: root_path
  end

  # PATCH/PUT /academic_records/1 or /academic_records/1.json
  def update
    respond_to do |format|      
      if @academic_record.update(academic_record_params)
        flash[:success] = '¡Actualización Exitosa!'
        format.html { redirect_back fallback_location: root_path}
        format.json { render json: {data: '¡Datos Guardados con éxito!', type: 'success'}, status: :ok }
      else
        flash[:danger] = @academic_record.errors.full_messages.to_sentence

        format.html { redirect_back fallback_location: root_path}
        format.json { render json: {data: "Error: #{@academic_record.errors.full_messages.to_sentence}", type: 'danger'}, status: :ok }
        # format.json { render json: @academic_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /academic_records/1 or /academic_records/1.json
  def destroy
    student_id = @academic_record.student.id
    @academic_record.destroy
    flash[:info] = '¡Registro Eliminado!'

    respond_to do |format|
      format.html { redirect_back fallback_location: "/admin/student/#{student_id}"}
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_academic_record
      @academic_record = AcademicRecord.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def academic_record_params
      params.require(:academic_record).permit(:section_id, :enroll_academic_process_id, :status)
    end

    # Refuerzo server-side de la política de Control de Estudios. La vista
    # esconde el formulario para roles no autorizados, pero esto blinda el
    # endpoint contra POSTs directos (curl/Postman/devtools) que esquiven la UI.
    def ensure_can_manage_academic_records!
      return if current_user&.admin&.can_manage_academic_records?

      flash[:danger] = 'No autorizado: solo el Jefe de Control de Estudios puede registrar asignaturas en una inscripción.'
      redirect_back(fallback_location: root_path)
    end
end
