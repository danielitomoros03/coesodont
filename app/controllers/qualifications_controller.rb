class QualificationsController < ApplicationController
  before_action :set_academic_record, only: %i[ update ]
  before_action :logged_as_teacher_or_admin?, only: %i[ update ]

  # PATCH/PUT /academic_records/1 or /academic_records/1.json
  def update
    respond_to do |format|
      
      if qualification_params[:value].eql? '-2'
        if @academic_record.qualifications.find_by(type_q: qualification_params[:type_q])&.destroy
          format.js { render json: {data: '¡Datos Guardados con éxito!', type: 'success'}, status: :ok}
        else
          format.js { render json: {data: "Error: #{@academic_record.errors.full_messages.to_sentence}", type: 'danger'}, status: :ok }
        end
      else
        qua = @academic_record.qualifications.find_or_initialize_by(type_q: qualification_params[:type_q])
        qua.value = qualification_params[:value]      
        if qua.save
          format.js { render json: {data: '¡Datos Guardados con éxito!', type: 'success'}, status: :ok}
        else
          format.js { render json: {data: "Error: #{qua.errors.full_messages.to_sentence}", type: 'danger'}, status: :ok }
        end
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_academic_record
      @academic_record = AcademicRecord.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def qualification_params
      params.require(:qualification).permit(:type_q, :value)
    end
end
