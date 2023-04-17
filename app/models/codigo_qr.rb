class CodigoQr

  def self.generate_image link

    require 'rqrcode'
    
    qrcode = RQRCode::QRCode.new(link)

    png = qrcode.as_png(
      bit_depth: 2,
      border_modules: 2,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: "tmp/barcode.png",
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 180
    )

    return "#{Rails.root.to_s}/tmp/barcode.png"

  end

end
