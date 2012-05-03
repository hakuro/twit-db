#!/usr/bin/env ruby
require "yaml"
require "logger"
require "rubygems"
require "active_record"

ActiveRecord::Base.configurations = YAML.load_file("config/database.yaml")
ActiveRecord::Base.establish_connection('production')

ActiveRecord::Base.logger = Logger.new(STDOUT)


task :migrate do
    ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
end

