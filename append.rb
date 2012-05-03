#!/usr/bin/env ruby
# _*_ coding: utf-8 _*_

require "date"
require "yaml"
require "rubygems"
require "active_record"

ActiveRecord::Base.configurations = YAML.load_file("config/database.yaml")
ActiveRecord::Base.establish_connection('production')

today = (Time.now + 3600*24).strftime("%Y%m%d")
next_day = (Time.now + 3600*24*2).strftime("%Y%m%d")
ActiveRecord::Base.connection.execute <<-EOS
    alter table tweets REORGANIZE PARTITION prt_max into (
        partition prt_#{today} values less than (to_days('#{next_day}')),
        partition prt_max values less than MAXVALUE
    )
EOS
