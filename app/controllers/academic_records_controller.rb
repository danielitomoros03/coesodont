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
  end

  # GET /academic_records/1/edit
  def edit
  end

  # POST /academic_records or /academic_records.json
  def create
    @academic_record = AcademicRecord.new(academic_record_params)

    respond_to do |format|
      if @academic_record.save
        format.html { redirect_to academic_record_url(@academic_record), notice: "Academic record was successfully created." }
        format.json { render :show, status: :created, location: @academic_record }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @academic_record.errors, status: :unprocessable_entity }
      end
    end
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
    @academic_record.destroy
    flash[:info] = '¡Registro Eliminado!'

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path}
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
      params.require(:academic_record).permit(:section_id, :enroll_academic_process_id, :status, :pi)
    end
end
