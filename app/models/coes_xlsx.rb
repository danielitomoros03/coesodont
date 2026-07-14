# Writer XLSX de marca COESODONT construido sobre xlsxtream (streaming, memoria
# acotada). Todo el estilo vive en la CABECERA (costo único): el camino de datos
# usa el <<(row) original de xlsxtream, así que exportar alto volumen sigue
# streameando fila por fila sin acumular en memoria.
#
# Limitación heredada de xlsxtream: no hay zebra ni bordes por celda de datos
# (requerirían estilar cada celda de cada fila = justo el costo que queremos
# evitar). El violeta se concentra en las bandas de título/grupo/cabecera.
require 'xlsxtream'

module CoesXlsx
  # Paleta de marca (violeta del navbar = $cool-primary/#330066).
  VIOLET    = 'FF330066' # ARGB: cabecera / título
  VIOLET_2  = 'FF4C1A85' # ARGB: banda de grupos
  ON_VIOLET = 'FFF2ECFB' # ARGB: texto casi blanco

  # Índices de cellXf añadidos DESPUÉS de los de xlsxtream (0=normal, 1=fecha,
  # 2=hora) para no romper el formateo de fechas de las filas de datos.
  TITLE_STYLE  = 3
  GROUP_STYLE  = 4
  HEADER_STYLE = 5

  # 0-based => letras de columna Excel (0 => "A", 26 => "AA").
  def self.col_ref(index)
    letters = +''
    n = index
    loop do
      letters.prepend(('A'.ord + (n % 26)).chr)
      n = n / 26 - 1
      break if n.negative?
    end
    letters
  end

  class Workbook < Xlsxtream::Workbook
    private

    # Igual que el padre pero instancia CoesXlsx::Worksheet y le pasa las
    # opciones extra (freeze/autofilter/merges).
    def build_worksheet(name = nil, options = {})
      if name.is_a?(Hash) && options.empty?
        options = name
        name = nil
      end

      sheet_id = @worksheets.size + 1
      name ||= options[:name] || "Sheet#{sheet_id}"
      use_sst = options.fetch(:use_shared_strings, @options[:use_shared_strings])

      @writer.add_file "xl/worksheets/sheet#{sheet_id}.xml"
      worksheet = Worksheet.new(@writer,
                                id: sheet_id,
                                name: name,
                                sst: use_sst ? @sst : nil,
                                auto_format: options.fetch(:auto_format, @options[:auto_format]),
                                columns: options.fetch(:columns, @options[:columns]),
                                freeze_rows: options[:freeze_rows].to_i,
                                freeze_cols: options[:freeze_cols].to_i,
                                autofilter: options[:autofilter],
                                merges: Array(options[:merges]))
      @worksheets << worksheet
      worksheet
    end

    # styles.xml de marca: conserva numFmts/estilos 0-2 de xlsxtream y añade
    # fuentes/rellenos violeta + cellXf 3-5 (título, grupo, cabecera).
    def write_styles
      font = @options.fetch(:font, {})
      size = font.fetch(:size, 11).to_s
      name = Xlsxtream::XML.escape_attr(font.fetch(:name, 'Calibri').to_s)

      @writer.add_file 'xl/styles.xml'
      @writer << Xlsxtream::XML.header
      @writer << Xlsxtream::XML.strip(<<-XML)
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <numFmts count="2">
            <numFmt numFmtId="164" formatCode="yyyy\\-mm\\-dd"/>
            <numFmt numFmtId="165" formatCode="yyyy\\-mm\\-dd hh:mm:ss"/>
          </numFmts>
          <fonts count="3">
            <font><sz val="#{size}"/><name val="#{name}"/><family val="2"/></font>
            <font><b/><sz val="11"/><color rgb="#{ON_VIOLET}"/><name val="#{name}"/><family val="2"/></font>
            <font><b/><sz val="14"/><color rgb="#{ON_VIOLET}"/><name val="#{name}"/><family val="2"/></font>
          </fonts>
          <fills count="4">
            <fill><patternFill patternType="none"/></fill>
            <fill><patternFill patternType="gray125"/></fill>
            <fill><patternFill patternType="solid"><fgColor rgb="#{VIOLET}"/></patternFill></fill>
            <fill><patternFill patternType="solid"><fgColor rgb="#{VIOLET_2}"/></patternFill></fill>
          </fills>
          <borders count="1"><border/></borders>
          <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
          <cellXfs count="6">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
            <xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
            <xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
            <xf numFmtId="0" fontId="2" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="left" vertical="center" indent="1"/></xf>
            <xf numFmtId="0" fontId="1" fillId="3" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>
            <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>
          </cellXfs>
          <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
          <dxfs count="0"/>
          <tableStyles count="0" defaultTableStyle="TableStyleMedium9" defaultPivotStyle="PivotStyleLight16"/>
        </styleSheet>
      XML
    end
  end

  class Worksheet < Xlsxtream::Worksheet
    # Escribe una fila con un cellXf fijo (para las bandas de cabecera). Las
    # celdas vacías igual se pintan (para que el color abarque las fusiones).
    def styled_row(values, style, height: nil)
      attrs = %Q{ r="#{@rownum}"}
      attrs << %Q{ ht="#{height}" customHeight="1"} if height
      xml = String.new("<row#{attrs}>")
      col = String.new('A')
      values.each do |v|
        cid = "#{col}#{@rownum}"
        col.next!
        if v.nil? || v.to_s.empty?
          xml << %Q{<c r="#{cid}" s="#{style}"/>}
        else
          xml << %Q{<c r="#{cid}" s="#{style}" t="inlineStr"><is><t>#{Xlsxtream::XML.escape_value(v.to_s)}</t></is></c>}
        end
      end
      xml << '</row>'
      @io << xml
      @rownum += 1
    end

    private

    # Inserta <sheetViews> (freeze) antes de <cols>/<sheetData>.
    def write_header
      @io << Xlsxtream::XML.header
      @io << %Q{<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">}

      fr = @options[:freeze_rows].to_i
      fc = @options[:freeze_cols].to_i
      if fr.positive? || fc.positive?
        top_left = "#{CoesXlsx.col_ref(fc)}#{fr + 1}"
        pane = %Q{<pane}
        pane << %Q{ xSplit="#{fc}"} if fc.positive?
        pane << %Q{ ySplit="#{fr}"} if fr.positive?
        pane << %Q{ topLeftCell="#{top_left}" activePane="bottomRight" state="frozen"/>}
        @io << %Q{<sheetViews><sheetView tabSelected="1" workbookViewId="0">#{pane}<selection pane="bottomRight"/></sheetView></sheetViews>}
      end

      columns = Array(@options[:columns])
      @io << Xlsxtream::Columns.new(columns).to_xml unless columns.empty?
      @io << '<sheetData>'
    end

    # Cierra sheetData y añade autoFilter + mergeCells (orden del esquema OOXML).
    def write_footer
      @io << '</sheetData>'
      if (af = @options[:autofilter])
        @io << %Q{<autoFilter ref="#{af}"/>}
      end
      merges = Array(@options[:merges])
      unless merges.empty?
        @io << %Q{<mergeCells count="#{merges.size}">}
        merges.each { |ref| @io << %Q{<mergeCell ref="#{ref}"/>} }
        @io << '</mergeCells>'
      end
      @io << '</worksheet>'
    end
  end
end
