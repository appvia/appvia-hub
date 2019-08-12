module Admin
  class SettingsController < BaseController
    authorize_resource :settings, parent: false, class: false

    # GET /admin/settings
    def show
      @settings = SettingsService.all
    end

    # PUT /admin/settings
    def update
      SettingsService.update_all! params[:settings].permit!.to_hash

      redirect_to admin_settings_path,
        turbolinks: false,
        notice: 'Settings updated'
    end
  end
end
