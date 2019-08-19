module Authorization
  extend ActiveSupport::Concern

  included do
    check_authorization

    rescue_from CanCan::AccessDenied do |exception|
      logger.warn [
        "AUTHORIZATION FAIL: user #{current_user.id} (#{current_user.email})",
        'tried to a perform an action they are not authorized for:',
        "action = #{exception.action}, subject = #{exception.subject},",
        "message = #{exception.message}"
      ].join(' ')

      access_denied exception.message
    end

    def access_denied(message)
      respond_to do |format|
        format.js   { head :forbidden, content_type: 'text/html' }
        format.json { head :forbidden, content_type: 'text/html' }
        format.html { redirect_to root_path, alert: "Access denied: #{message}" }
      end
    end
  end
end
