class DownloaderController < ApplicationController

	def section_list
		# section = Section.find params[:id]
		# pdf = ExportPdf.section_list section
		# unless send_data pdf.render, filename: "listado_#{section.subject.id}_#{section.code}.pdf", type: "application/pdf", disposition: "attachment"
		# flash[:mensaje] = "en estos momentos no se pueden descargar las notas, intentelo luego."
		# end
		redirect_back fallback_location: root_path
	end
end
