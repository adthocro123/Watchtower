class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :track_last_seen

  after_action :pundit_verify, unless: :skip_pundit?
  before_action :auto_sync_event, if: :should_auto_sync?

  helper_method :current_event

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  # Returns the currently selected event from the session, or nil.
  def current_event
    return @current_event if defined?(@current_event)

    @current_event = session[:current_event_id].present? ? Event.find_by(id: session[:current_event_id]) : nil
  end

  # Before action to enforce that an event is selected.
  def require_event!
    return if current_event.present?

    redirect_to events_path, alert: "Please select an event first."
  end

  # Pundit user context — returns the current Devise user.
  def pundit_user
    current_user
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  def pundit_verify
    return if pundit_policy_authorized? || pundit_policy_scoped?
    raise Pundit::AuthorizationNotPerformedError, self.class
  end

  def skip_pundit?
    devise_controller? || self.class.ancestors.include?(ActionController::API)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [ :username ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end

  # Debounced auto-sync runs only on dashboard loads and executes in a
  # background job so page rendering is never blocked by external API calls.
  def should_auto_sync?
    request.get? &&
      request.format.html? &&
      current_user.present? &&
      current_event.present? &&
      controller_name == "dashboard" &&
      action_name == "index"
  end

  def auto_sync_event
    return unless TbaClient.configured?

    # Everything stays async to keep dashboard loads fast.
    AutoSyncEventJob.perform_later(current_event.id)
  rescue StandardError => e
    Rails.logger.warn("[ApplicationController] Auto-sync failed: #{e.message}")
  end

  def track_last_seen
    return unless current_user
    # Only update once per minute to avoid hammering the DB on every request
    if current_user.last_seen_at.nil? || current_user.last_seen_at < 1.minute.ago
      current_user.update_columns(last_seen_at: Time.current)
    end
  end
end
