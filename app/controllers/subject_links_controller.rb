class SubjectLinksController < ApplicationController
  before_action :logged_as_admin?
  before_action :set_subject_link, only: %i[ destroy ]


  # DELETE /subjectlinks/1 or /subject_links/1.json
  def destroy
    @subject_link.destroy

    respond_to do |format|
      format.html { redirect_to subject_links_url, notice: "subject_link was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subject_link
      @subject_link = SubjectLink.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subject_link_params
      params.require(:subject_link).permit(:name, :school_id, :subject_link_id)
    end
end
