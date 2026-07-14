class ExcelConverter
  # Filas a muestrear para calcular anchos de columna sin cargar todo en memoria
  # (el export completo se sigue streameando fila por fila).
  WIDTH_SAMPLE = 300

  def initialize(objects = [], schema = nil)
    @fields = []
    @associations = []
    schema ||= {}

    return self if (@objects = objects).blank?

    @model = objects.dup.first.class
    @abstract_model = RailsAdmin::AbstractModel.new(@model)
    @model_config = @abstract_model.config
    @methods = [(schema[:only] || []) + (schema[:methods] || [])].flatten.compact
    @fields = @methods.collect { |m| export_field_for(m) }.compact
    @empty = ::I18n.t('admin.export.empty_value_for_associated_objects')
    schema_include = schema.delete(:include) || {}

    @associations = schema_include.each_with_object({}) do |(key, values), hash|
      association = export_field_for(key)
      next unless association&.association?

      model_config = association.associated_model_config
      abstract_model = model_config.abstract_model
      methods = [(values[:only] || []) + (values[:methods] || [])].flatten.compact

      hash[key] = {
        association: association,
        model: abstract_model.model,
        abstract_model: abstract_model,
        model_config: model_config,
        fields: methods.collect { |m| export_field_for(m, model_config) }.compact,
      }
      hash
    end
  end

  # Método específico para CSV streaming que evita conflictos de ordenamiento
  def to_csv_streaming(response_stream)
    p "  Iniciando exportación CSV streaming    ".center(1000, 'C')
    
    # Generar encabezados
    headers = generate_excel_header
    response_stream.write headers.join(";") + "\n"
    
    processed_count = 0
    batch_size = 20
    
    # Usar find_each sin ordenamiento específico para evitar conflictos
    if @objects.respond_to?(:reorder)
      # Remover cualquier ordenamiento que pueda causar conflictos
      objects_to_process = @objects.reorder(nil)
    else
      objects_to_process = @objects
    end
    
    objects_to_process.find_each(batch_size: batch_size) do |object|
      row_data = generate_excel_row(object)
      response_stream.write row_data.join(";") + "\n"
      processed_count += 1
    end

  end

  # XLSX de marca COESODONT en STREAMING (memoria acotada): banda de título,
  # banda de grupos por asociación, cabecera violeta con texto casi blanco,
  # anchos de columna, cabecera y 1ª columna congeladas, y auto-filtro.
  # El cuerpo se escribe fila por fila con el writer original de xlsxtream, así
  # que exportar alto volumen no acumula el libro en memoria (requisito duro).
  def to_xlsx_streaming(response_stream)
    columns = build_column_plan

    if columns.empty?
      CoesXlsx::Workbook.open(response_stream) { |wb| wb.write_worksheet('Datos') { |_s| } }
      return
    end

    ncols      = columns.size
    root_label = @abstract_model.pretty_name.to_s
    title      = "#{root_label} · Reporte COES — #{Time.zone.now.strftime('%d/%m/%Y %H:%M')}"

    # Bandas de grupo (fila 1 = título, fila 2 = grupos, fila 3 = campos).
    runs = group_runs(columns, root_label)
    band = Array.new(ncols)
    runs.each { |start_i, _end_i, label| band[start_i] = label }
    header_labels = columns.map { |c| c[:field].label }

    merges = []
    merges << "A1:#{CoesXlsx.col_ref(ncols - 1)}1" if ncols > 1                       # título
    runs.each { |s, e, _| merges << "#{CoesXlsx.col_ref(s)}2:#{CoesXlsx.col_ref(e)}2" if e > s } # grupos

    col_opts    = sample_column_widths(header_labels, ncols)
    freeze_cols = ncols > 4 ? 1 : 0
    autofilter  = "A3:#{CoesXlsx.col_ref(ncols - 1)}3"

    CoesXlsx::Workbook.open(response_stream) do |wb|
      wb.write_worksheet('Datos', columns: col_opts, freeze_rows: 3, freeze_cols: freeze_cols,
                                  autofilter: autofilter, merges: merges) do |sheet|
        sheet.styled_row([title] + Array.new(ncols - 1), CoesXlsx::TITLE_STYLE, height: 26)
        sheet.styled_row(band, CoesXlsx::GROUP_STYLE, height: 18)
        sheet.styled_row(header_labels, CoesXlsx::HEADER_STYLE, height: 26)

        records = @objects.respond_to?(:find_each) ? @objects.find_each(batch_size: 500) : @objects
        records.each { |object| sheet << generate_excel_row(object) }
      end
    end
  end

  private

  # Plan de columnas en el mismo orden que generate_excel_row:
  # primero los campos raíz, luego los de cada asociación (con su etiqueta de grupo).
  def build_column_plan
    plan = @fields.map { |f| { field: f, group: nil } }
    @associations.each do |_name, opt|
      label = opt[:association].label
      opt[:fields].each { |f| plan << { field: f, group: label } }
    end
    plan
  end

  # Tramos contiguos de columnas que comparten grupo, para fusionar la banda.
  # => [[col_ini, col_fin, etiqueta], ...]
  def group_runs(columns, root_label)
    columns.each_with_index.each_with_object([]) do |(c, i), runs|
      label = c[:group] || root_label
      if runs.any? && runs.last[2] == label && runs.last[1] == i - 1
        runs.last[1] = i
      else
        runs << [i, i, label]
      end
    end
  end

  # Anchos por columna. Los <cols> deben declararse ANTES de streamear los datos,
  # así que estimamos con las etiquetas de cabecera + una muestra acotada de filas
  # (WIDTH_SAMPLE) para no cargar todo el dataset en memoria. Se acotan a [12, 48].
  def sample_column_widths(header_labels, ncols)
    widths = header_labels.map { |l| l.to_s.length }
    sample = @objects.respond_to?(:limit) ? @objects.limit(WIDTH_SAMPLE) : Array(@objects).first(WIDTH_SAMPLE)
    sample.each do |object|
      generate_excel_row(object).each_with_index { |v, i| widths[i] = [widths[i], v.to_s.length].max if i < ncols }
    end
    widths.map { |w| { width_chars: [[w + 3, 12].max, 48].min } }
  end

  def export_field_for(method, model_config = @model_config)
    model_config.export.fields.detect { |f| f.name == method }
  end

  def generate_excel_header
    @fields.collect do |field|
      ::I18n.t('admin.export.csv.header_for_root_methods', name: field.label, model: @abstract_model.pretty_name)
    end +
      @associations.flat_map do |_association_name, option_hash|
        option_hash[:fields].collect do |field|
          ::I18n.t('admin.export.csv.header_for_association_methods', name: field.label, association: option_hash[:association].label)
        end
      end
  end

  def generate_excel_row(object)
    @fields.collect do |field|
      field.with(object: object).export_value
    end +
      @associations.flat_map do |association_name, option_hash|
        associated_objects = [object.send(association_name)].flatten.compact
        option_hash[:fields].collect do |field|
          associated_objects.collect { |ao| field.with(object: ao).export_value.presence || @empty }.join(',')
        end
      end
  end
end
