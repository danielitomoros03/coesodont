# frozen_string_literal: true
# require 'rails_admin/config/actions'
# require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class Export < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        include ActionController::Live
        
        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          %i[get post]
        end


        register_instance_option :controller do
          proc do
            # format = params[:json] && :json || params[:csv] && :csv || params[:xml] && :xml
            if request.post?
              request.format = :xlsx

              @schema = HashHelper.symbolize(params[:schema].slice(:except, :include, :methods, :only).permit!.to_h) if params[:schema] # to_json and to_xml expect symbols for keys AND values.
              @objects = list_entries(@model_config, :export)
              
              begin
                unless @model_config.list.scopes.empty?
                  if params[:scope].blank?
                    @objects = @objects.send(@model_config.list.scopes.first) unless @model_config.list.scopes.first.nil?
                  elsif @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
                    @objects = @objects.send(params[:scope].to_sym)
                  end
                end

                # Configurar headers para streaming y evitar timeouts
                response.headers.delete('Content-Length')
                response.headers['Cache-Control'] = 'no-cache'
                
                
                # response.headers['Content-Type'] = "Content-Type: text/csv; charset=utf-8\n"
                response.headers['Content-Type'] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

                response.headers['X-Accel-Buffering'] = 'no'
                response.headers['ETag'] = '0'
                response.headers['Last-Modified'] = '0'
                response.headers['Connection'] = 'keep-alive'
                
                # aux = "Reporte Coes - #{I18n.t("activerecord.models.#{params[:model_name]}.other")&.titleize} #{DateTime.now.strftime('%d-%m-%Y_%I:%M%P')}.csv"
                # response.headers['Content-Disposition'] = "attachment; filename=#{aux}"
                
                aux = "Reporte Coes - #{I18n.t("activerecord.models.#{params[:model_name]}.other")&.titleize} #{DateTime.now.strftime('%d-%m-%Y_%I:%M%P')}.xlsx"
                response.headers['Content-Disposition'] = "attachment; filename=\"#{aux}\""

                # Determinar el método de exportación basado en el tamaño del dataset
                total_count = @objects.count
                excel_converter = ExcelConverter.new(@objects, @schema)
                
                Rails.logger.info "Iniciando exportación de #{total_count} registros"
                                
                p "     Exportando dataset grande (#{total_count} registros) usando streaming SIMPLE ".center(1000, '#')
                excel_converter.to_xlsx_streaming(response.stream)
                
                # p "     Exportando dataset grande (#{total_count} registros) usando streaming GENERAL".center(1000, '#')
                # excel_converter.to_csv_streaming(response.stream)
                
                Rails.logger.info "Exportación completada"
                
              rescue => e
                Rails.logger.error "Error en exportación: #{e.message}"
                Rails.logger.error e.backtrace.join("\n")
                response.stream.write("Error en la exportación: #{e.message}")
              ensure
                response.stream.close
              end
              
            else
              render @action.template_name
            end
          end
        end

        register_instance_option :bulkable? do
          true
        end

        register_instance_option :link_icon do
          'fas fa-file-export'
        end
      end
    end
  end
end