class AddressesController < ApplicationController
  before_action :set_address, only: %i[ edit update ]
  before_action :set_student, only: %i[ new created ]
  before_action :authenticate_student!

  layout 'logged'
  # GET /addresses/new
  def new
    @address = Address.new
    @address.student = @student
  end

  # GET /addresses/1/edit
  def edit
  end

  # POST /addresses or /addresses.json
  def create
    @address = Address.new(address_params)

    respond_to do |format|
      if @address.save
        flash[:success] = 'Dirección guardada con éxito.'
        flash[:success] += ' Gracias por suministrar la información solicitada.' if @address.student.complete_info?
      else
        flash[:danger] = "#{@address.errors.full_messages.to_sentence}"
      end
      format.html { redirect_to student_session_dashboard_url }
    end
  end



  # PATCH/PUT /addresses/1 or /addresses/1.json
  def update
    respond_to do |format|
      if @address.update(address_params)
        flash[:success] = 'Dirección guardada con éxito.'
      else
        flash[:danger] = "#{@address.errors.full_messages.to_sentence}"
      end
      format.html { redirect_to student_session_dashboard_url }
    end
  end

  def getMunicipalities
    render json: Address.municipalities(params[:term]), status: :ok
  end

  def getCities
    render json: Address.cities(params[:state], params[:term]), status: :ok
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_address
      @address = Address.find(params[:id])
    end

    def set_student
      @student = Student.find(params[:student_id])
    end    

    # Only allow a list of trusted parameters through.
    def address_params
      params.require(:address).permit(:student_id, :state, :municipality, :city, :sector, :street, :house_type, :house_name)
    end
end
