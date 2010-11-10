# -*- ruby -*-

namespace :groonga do
  task :load_config => :rails_env do
    require 'erb'
    require 'pathname'
    groonga_yml = Rails.root + "config" + "groonga.yml"
    unless groonga_yml.exist?
      groonga_yml_example = Rails.root + "config" + "groonga.yml.example"
      cp(groonga_yml_example, groonga_yml)
    end
    config = YAML.load(ERB.new(IO.read(groonga_yml)).result)
    Rails.application.config.groonga_configurations = config
  end

  desc "Drops the database."
  task :drop => :load_config do
    configurations = Rails.application.config.groonga_configurations
    config = configurations[Rails.env || "development"]
    rm_rf(File.dirname(config["database"]))
  end

  desc "Create the database and load the schema."
  task :create => :load_config do
    require "ranguba/database"
    configurations = Rails.application.config.groonga_configurations
    config = configurations[Rails.env || "development"]
    database = Ranguba::Database.new
    database.populate(config["database"])
    database.close
  end

  namespace :schema do
    desc "Create the database and load the schema."
    task :load => "groonga:load_config" do
      require "ranguba/database"
      configurations = Rails.application.config.groonga_configurations
      config = configurations[Rails.env || "development"]
      Ranguba::Database.open(config["database"]) do |database|
        database.populate_schema
      end
    end
  end

  desc "Create the database and load the schema."
  task :setup => [:create, "groonga:schema:load"]

  task :reset => [:drop, :setup]
end
