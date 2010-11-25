class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_locale, :set_ranguba_template, :load_labels

  private
  def set_locale
    I18n.locale = extract_locale_from_accept_language_header
  end

  def extract_locale_from_accept_language_header
    accept_language = request.env["HTTP_ACCEPT_LANGUAGE"]
    accept_language ? accept_language.scan(/^[a-z]{2}/).first : nil
  end

  def set_ranguba_template
    @ranguba_template = Ranguba::Template.new
  end

  def load_labels
    Ranguba::CategoryLoader.new.load_labels
    Ranguba::TypeLoader.new.load_labels
  end
end
