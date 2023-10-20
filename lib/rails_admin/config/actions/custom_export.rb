# app/rails_admin/config/actions/custom_export.rb

module RailsAdmin
  module Config
    module Actions
      class CustomExport < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :link_icon do
          'icon-share'
        end

        register_instance_option :collection? do
          true # Makes action tab visible for the collection
        end

        register_instance_option :http_methods do
          %i[get post]
        end

        register_instance_option :controller do
          proc do
            begin
              if request.get?
                render action: @action.template_name

              elsif request.post?
                from = Time.zone.parse(params[:from])

                # Prepare headers for streaming
                response.headers.delete('Content-Length')
                response.headers['Cache-Control'] = 'no-cache'
                response.headers['X-Accel-Buffering'] = 'no'
                response.headers['Content-Type'] = 'text/event-stream'

                # There's an issue in rack where ActionController::Live doesn't work with the ETags middleware
                # See https://github.com/rack/rack/issues/1619#issuecomment-606315714
                response.headers['ETag'] = '0'
                response.headers['Last-Modified'] = '0'

                # Download response stream into a file
                response.headers['Content-Disposition'] = "attachment; filename=testfile.txt"

                AcademicRecord.where('created_at > ?', from).find_each(batch_size: 500) do |record|
                  # Define how the records should be exported
                  response.stream.write record.to_s
                end
              end
            ensure
              response.stream.close
            end
          end
        end
      end
    end
  end
end