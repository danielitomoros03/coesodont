class SectionsController < ApplicationController
  before_action :set_section, only: %i[ show update export ]

  # GET /sections or /sections.json
  def index
    @sections = Section.all
  end

  def export
    respond_to do |format|
      format.xls {send_file @section.excel_list, filename: "Listado_Sec_#{@section.name_to_file}.xls", disposition: 'inline'}
    end
  end

  # GET /sections/1 or /sections/1.json
  def show
    if current_admin or (current_teacher and @section.teacher and @section.teacher_id.eql? current_teacher.id)
      @subject = @section.subject
      @period = @section.period
      @school = @section.school
      @academic_records = @section.academic_records.sort_by_user_name

      respond_to do |format|
        format.html
        format.pdf do
          render pdf: "ACTA#{@section.number_acta}", template: "sections/acta", formats: [:html], page_size: 'letter', footer: {center: "Página: [page] de [topage]", font_size: '8'}
          # , header: {content: render_to_string('sections/acta_header')} 
        end

      end
    else
      flash[:warning] = 'Sección no asignada'
      redirect_back fallback_location: root_path
    end
  end

  # GET /sections/new
  # def new
  #   @section = Section.new
  # end

  # GET /sections/1/edit
  # def edit
  # end

  # POST /sections or /sections.json
  # def create
  #   @section = Section.new(section_params)

  #   respond_to do |format|
  #     if @section.save
  #       format.html { redirect_to section_url(@section), notice: "Section was successfully created." }
  #       format.json { render :show, status: :created, location: @section }
  #     else
  #       format.html { render :new, status: :unprocessable_entity }
  #       format.json { render json: @section.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # PATCH/PUT /sections/1 or /sections/1.json
  def update
    if @section.totaly_qualified?
      msg, type = @section.update(section_params) ? ["¡Sección calificada con éxito!", 'success'] : [@section.errors.full_messages.to_sentence, 'danger']
    else
      msg, type = ['Atención: No se pudo cerrar la calificación, faltan calificaciones por completar. Por favor refresque la pantalla e inténte calificar los registros restantes.', 'danger']
    end
    flash[type] = msg
    redirect_back fallback_location: section_url(@section)

  end

  # DELETE /sections/1 or /sections/1.json
  # def destroy
  #   @section.destroy

  #   respond_to do |format|
  #     format.html { redirect_to sections_url, notice: "Section was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_section
      @section = Section.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def section_params
      params.require(:section).permit(:code, :capacity, :course_id, :teacher_id, :qualified, :modality, :enabled)
    end
end
