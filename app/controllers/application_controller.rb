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
    encodings = Rails.configuration.ranguba_config_encodings
    @ranguba_template = Ranguba::Template.new(encodings)
  end

  def load_labels
    encodings = Rails.configuration.ranguba_config_encodings
    Ranguba::CategoryLoader.new(encodings['categories.csv']).load_labels
    Ranguba::TypeLoader.new(encodings['types.csv']).load_labels
  end
end
