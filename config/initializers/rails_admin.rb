require 'same_period_validator'

Dir[Rails.root.join('app', 'rails_admin', '**/*.rb')].each { |file| require file }

# RailsAdmin::Config::Actions.register(:custom_export, RailsAdmin::Config::Actions::CustomExport)

# Filtros enum más limpios: el "..." pasa a decir "Todos" y se eliminan las
# opciones "Está presente"/"Está vacío" (ruido visual). El JS del gem ya sabe
# renderizar operadores tipo objeto {label, value}, así que no hace falta tocarlo.
RailsAdmin::Config::Fields::Types::Enum.class_eval do
  register_instance_option :filter_operators do
    [{ label: 'Todos', value: '_discard' }] +
      enum.map { |label, value| { label: label, value: value || label } }
  end
end

# Enriquece /admin/section/:id/history con versiones de AcademicRecord y Qualification
# además de las del propio Section. Mantiene el URL y la pestaña nativos de Rails Admin.
Rails.application.config.to_prepare do
  RailsAdmin::MainController.prepend(Module.new do
    # Listados que arrancan filtrados al período más reciente con datos, para no
    # escanear tablas enormes mostrando todos los períodos por defecto.
    DEFAULT_PERIOD_FILTER_MODELS = %w[Section EnrollAcademicProcess Course AcademicRecord PaymentReport].freeze

    def history_show(*args)
      action = RailsAdmin::Config::Actions.find(:history_show)
      get_model unless action.root?
      get_object if action.member?
      @authorization_adapter.try(:authorize, action.authorization_key, @abstract_model, @object)
      @action = action.with({controller: self, abstract_model: @abstract_model, object: @object})
      raise(RailsAdmin::ActionNotAllowed) unless @action.enabled?
      @page_name = wording_for(:title)

      if @abstract_model&.model_name == 'Section' && @object.present?
        @general = false
        @bitacora = Section::BitacoraQuery.new(@object, params.slice(:tab, :student_ci, :all, :page, :per_page))
        @history = @bitacora.call
        @bitacora_total_count = @history.respond_to?(:total_count) ? @history.total_count : @history.size
        @bitacora_focused_student = @bitacora.focused_student
        @bitacora_tab = @bitacora.tab
        @bitacora_tab_counts = @bitacora.tab_counts
        render @action.template_name
      else
        instance_eval(&@action.controller)
      end
    end

    # Preselecciona el período más reciente en el listado cuando el usuario entra
    # sin filtros propios. `index` se despacha vía action_missing (no hay método
    # concreto), así que ese es el punto de enganche.
    def action_missing(name, *args, &block)
      apply_default_period_filter if name.to_sym == :index
      super
    end

    private

    def apply_default_period_filter
      return if params[:f].present? || params[:scope].present? || params[:query].present?

      get_model
      return unless DEFAULT_PERIOD_FILTER_MODELS.include?(@abstract_model&.model_name.to_s)

      period_field = @model_config.list.fields.detect { |f| f.name == :period && f.filterable? }
      most_recent_id = period_field&.with(controller: self)&.enum&.first&.last
      return unless most_recent_id

      params[:f] = ActionController::Parameters.new('period' => { '0' => { 'v' => most_recent_id.to_s } })
    end
  end)
end

RailsAdmin.config do |config|
  config.asset_source = :webpack

  ### Popular gems integration
  # config.main_app_name = Proc.new { |controller| [ "Coes", "ODONT - #{I18n.t(controller.params[:action]).try(:titleize)}" ] }
  config.main_app_name = Proc.new { |controller| [ "Coes", "ODONT" ] }

  ## == Devise ==
  config.authenticate_with do
    begin
      warden.authenticate! scope: :user
    rescue Exception => e
      reset_session
      flash[:danger] = "Por favor inicie sesión antes de continuar" 
      redirect_to '/users/sign_in'
    end
  end
  config.current_user_method(&:current_user)

  ## == CancanCan ==
  config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  config.show_gravatar = false

  config.label_methods << :description # Default is [:name, :title]

  # NO FUNCIONA
  # config.show_gravatar do |config|
  #   config.gravatar_url do
  #     main_app.url_for(current_user.profile_picture_as_thumbs)
  #   end
  # end

  # IMPORTER:

  config.configure_with(:import) do |config|
    config.logging = false
    config.line_item_limit = 3000
    config.update_if_exists = true
    config.rollback_on_error = false
  end

  # config.navigation_static_links = {
  #   'Cambiar Período' => 'http://www.google.com'
  # }
  # config.navigation_static_label = "Opciones"

  config.actions do
    dashboard do                     # mandatory
      # require_relative '../../lib/rails_admin/config/actions/dashboard'
      show_in_menu false
      show_in_navigation false
      visible false
    end

    index do                         # mandatory

      require_relative '../../lib/rails_admin/config/actions/index'
      except [SectionTeacher, Profile, Address, EnrollmentDay, Qualification, SubjectLink]
      # except [Address, SectionTeacher, Profile, User, StudyPlan, Period, Course, Faculty]

    end

    member :programation do 
      # subclass Base. Accessible at /admin/<model_name>/<id>/my_member_action
      only [AcademicProcess]
      # i18n_key :edit # will have the same menu/title labels as the Edit action.
      link_icon do
          'fa-solid fa-shapes'
      end
    end

    # member :organization_chart do 

    #   only [School]
    #   link_icon do
    #       'fa-solid fa-shapes'
    #   end
    # end

    member :enrollment_day do 

      only [AcademicProcess]
      link_icon do
          'fa-solid fa-bell'
      end
    end

    member :personal_data do 
      only [Student]
      link_icon do
          'fa-solid fa-id-card'
      end
    end

    member :structure do 
      only [StudyPlan]
      link_icon do
          'fa-solid fa-folder-tree'
      end
    end    

    new do
      except [School, Faculty, EnrollAcademicProcess, Course]
    end

    export do
      require_relative '../../lib/rails_admin/config/actions/export'
      except [Faculty, School, StudyPlan, GroupTutorial, Tutorial, ParentArea]
    end

    bulk_delete do
      only [AcademicRecord, Section]
    end

    show do
      except [AcademicRecord]
    end

    edit do
      except [EnrollAcademicProcess, Course]
    end

    delete do
      except [School, StudyPlan, Faculty, EnrollAcademicProcess, Course]
    end

    import do
      only [Student, Teacher, Subject, Section, AcademicRecord]
    end
    # show_in_app

    ## With an audit adapter, you can add:
    history_index do
      except [School, StudyPlan, ParentArea]
    end

    history_show do
      except [School, StudyPlan, ParentArea]
    end
  end

  # config.model Section do
  #   field :course do
  #     # visible false
  #     associated_collection_cache_all false  # REQUIRED if you want to SORT the list as below
  #     associated_collection_scope do
  #       # bindings[:object] & bindings[:controller] are available, but not in scope's block!
  #       # team = bindings[:object]
  #       Proc.new { |scope|
  #         # scoping all Players currently, let's limit them to the team's league
  #         # Be sure to limit if there are a lot of Players and order them by position
  #         scope = scope.joins(:course)
  #         scope = scope.limit(30) # 'order' does not work here
  #       }
  #     end
  #   end
  # end



  config.model "ActionText::EncryptedRichText" do
    visible false
  end

  config.model "ActionText::RichText" do
    visible false
  end  

  # config.model 'User' do
  #   configure :preview do
  #     children_fields [:name, :last_name, :email, :ci]
  #   end
  # end

  config.model "ActiveStorage::Blob" do
    visible false
  end
  config.model "ActiveStorage::Attachment" do
    visible false
  end
  config.model "ActiveStorage::VariantRecord" do
    visible false
  end

  config.parent_controller = 'EnhancedController'
end
