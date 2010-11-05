class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_locale

  private
  def set_locale
    I18n.locale = extract_locale_from_accept_language_header
  end

  def extract_locale_from_accept_language_header
    accept_language = request.env["HTTP_ACCEPT_LANGUAGE"]
    accept_language ? accept_language.scan(/^[a-z]{2}/).first : nil
  end 
end
