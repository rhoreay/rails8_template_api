module Authentication
  extend ActiveSupport::Concern
  include ApiResponses

  included do
    before_action :authenticate_request!
    helper_method :authenticated?, :current_user if respond_to?(:helper_method)
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :authenticate_request!, **options
    end
  end

  private
  def authenticate_request!
    token = extract_token_from_header!
    payload = JwtService.decode(token)

    case payload
    when :expired
      render_error(
        errors: [ "Expired token" ],
        status: :unauthorized
      )
    when Hash
      if (user = User.find_by(id: payload[:user_id]))
        Current.user = user
      else
        render_error(
          errors: [ "User not found" ],
          status: :unauthorized
        )
      end
    else
      render_error(
        errors: [ payload ],
        message: "Unauthorized",
        status: :unauthorized
      )
    end
  end

  def authenticated?
    Current.user.present?
  end

  def current_user
    Current.user
  end

  def extract_token_from_header!
    header = request.headers["Authorization"]
    header&.split(" ")&.last if header&.start_with?("Bearer ")
  end
end
