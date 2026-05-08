# frozen_string_literal: true
class SessionsController < ApplicationController
  skip_before_action :has_info
  skip_before_action :authenticated, only: [:new, :create]

  def new
    @url = params[:url]
    redirect_to home_dashboard_index_path if current_user
  end

  def create
    begin
      # Normalize the email address, why not
      user = User.authenticate(params[:email].to_s.strip.downcase, params[:password])
    rescue RuntimeError => e
      # don't do ANYTHING
    end

    if user
      if params[:remember_me]
        cookies.permanent[:auth_token] = user.auth_token
      else
        session[:user_id] = user.id
      end
      redirect_to post_authentication_redirect_path
    else
      flash[:error] = e.message
      render "sessions/new"
    end
  end

  def destroy
    cookies.delete(:auth_token)
    reset_session
    redirect_to root_path
  end

  private

  def post_authentication_redirect_path(default_path: home_dashboard_index_path)
    path = params[:url] || default_path
    Rails.logger.info("Checking redirect path: '#{path}'")
    
    # Block external URLs (Open Redirect prevention)
    if path.start_with?('http://', 'https://', '//')
      Rails.logger.warn("Path '#{path}' is external - blocked for security ✗")
      return default_path
    end
    
    Rails.application.routes.recognize_path(path)
    Rails.logger.info("Path '#{path}' is valid ✓")
    path
  rescue ActionController::RoutingError => e
    Rails.logger.warn("Path '#{path}' is invalid ✗ - Error: #{e.message}")
    default_path
  end
end
