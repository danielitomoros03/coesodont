# wkhtmltopdf-binary's wrapper solo reconoce SO hasta Ubuntu 22.04; en hosts más
# nuevos (ej. Ubuntu 24.04) revienta con "Invalid platform" aunque el binario
# (estático) funcione igual. En esas máquinas, definir WKHTMLTOPDF_EXE en .env
# apuntando a un binario válido (ej. el wkhtmltopdf_ubuntu_22.04_amd64 del gem).
WickedPdf.config = {
  exe_path: ENV.fetch("WKHTMLTOPDF_EXE") { Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf") },
  enable_local_file_access: true,
  layout: "layouts/pdf",
  orientation: "Portrait",
  page_size: "letter",
  lowquality: true,
  zoom: 1
}
