require "ranguba/file_reader"
require "ranguba/encoding_loader"
require "ranguba/category_loader"
require "ranguba/type_loader"
require "ranguba/password_loader"
require "ranguba/template"
require "ranguba/topic_path"
require "ranguba/topic_path_item"

Rails.configuration.ranguba_config_encodings = Ranguba::EncodingLoader.new.load

