# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `render :pdf` call.
#
# To learn more, check out the README:
#
# https://github.com/mileszs/wicked_pdf/blob/master/README.md

module WickedPdfExePath
  # wkhtmltopdf-binary's wrapper solo reconoce SO hasta Ubuntu 22.04; en hosts
  # más nuevos (ej. Ubuntu 24.04 en dev) revienta con "Invalid platform" aunque
  # el binario funcione igual (es estático). Si existe el extraído local, se usa.
  def self.path
    local = Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf').sub(/wkhtmltopdf\z/, 'wkhtmltopdf_local')
    (Rails.env.development? && File.exist?(local)) ? local : Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')
  end
end

WickedPdf.config = {
  # Path to the wkhtmltopdf executable: This usually isn't needed if using
  # one of the wkhtmltopdf-binary family of gems.
  # exe_path: '/usr/local/bin/wkhtmltopdf',
  #   or
  exe_path: WickedPdfExePath.path,

  # Needed for wkhtmltopdf 0.12.6+ to use many wicked_pdf asset helpers
  enable_local_file_access: true


  # Layout file to be used for all PDFs
  # (but can be overridden in `render :pdf` calls)
  # layout: 'pdf.html',

  # Using wkhtmltopdf without an X server can be achieved by enabling the
  # 'use_xvfb' flag. This will wrap all wkhtmltopdf commands around the
  # 'xvfb-run' command, in order to simulate an X server.
  #
  # use_xvfb: true,
}

WickedPdf.config ||= {}
WickedPdf.config.merge!({
  layout: "layouts/pdf",
  orientation: "Portrait", # Landscape
  page_size: "letter",
  lowquality: true,
  zoom: 1
})