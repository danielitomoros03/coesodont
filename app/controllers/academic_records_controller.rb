class AcademicRecordsController < ApplicationController
  before_action :set_academic_record, only: %i[ show edit update destroy ]

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

    if enroll_academic_process = @academic_record.enroll_academic_process
      if subject = Subject.find(params[:course][:subject_id])
        if academic_process = @academic_record.academic_process
          course = Course.find_or_create_by(subject_id: subject.id, academic_process_id: academic_process.id)

          section = Section.find_or_initialize_by(course_id: course.id, code: params[:section_code])

          if section.new_record?
            section.capacity = 30
            section.modality = params[:eq] ? :equivalencia : :nota_final
          end

          if section.save 
            @academic_record.section = section

            if subject.absoluta?
              if params[:approved]
                @academic_record.status = :aprobado
              else
                @academic_record.status = :aplazado
              end
            elsif params[:pi]
              @academic_record.status = :perdida_por_inasistencia
            elsif params[:rt]
              @academic_record.status = :retirado
            end
            if @academic_record.save
              flash[:success] = 'Se guardó el historial ' 
              if subject.numerica? and @academic_record.sin_calificar?
                if params[:qualifications] 
                  qa = @academic_record.qualifications.new
                  qa.type_q = params[:qualifications][:type_q]
                  qa.value = params[:qualifications][:value]
                  if qa.save
                    flash[:success] += '¡Calificación cargada!'
                  else
                    flash[:danger] = "Error al intentar guardar la calificación: #{qa.errors.full_messages.to_sentence}"
                  end
                else
                  flash[:danger] = 'No se especificó la calificación'
                end
              end
            else
              flash[:danger] = "Error al intentar guardar el histórico: #{@academic_record.errors.full_messages.to_sentence}"
            end

          else
            flash[:danger] = 'Error al intentar guardar la sección. No se pudo completar el proceso:'+ section.errors.full_messages.to_sentence
          end

        else
          flash[:danger] = 'Periodo no encontrado'
        end
      else
        flash[:danger] = 'Asignatura no encontrada'
      end
    else
      flash[:danger] = 'Sin inscripción en sistema'
    end

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
      format.html { redirect_to "/admin/student/#{student_id}"}
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
end
