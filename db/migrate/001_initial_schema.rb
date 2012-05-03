#!/usr/bin/env ruby
require "rubygems"
require "active_record"

class InitialSchema < ActiveRecord::Migration
    def self.up
        today = Time.now.strftime("%Y%m%d")
        next_day = (Time.now + 3600*24).strftime("%Y%m%d")
        execute <<-EOS
            create table tweets (
                id bigint unsigned,
                created_at datetime,
                user_id int unsigned,
                text varchar(420),
                source varchar(256),
                in_reply_to_user_id int unsigned,
                in_reply_to_status_id bigint unsigned,
                retweeted boolean,
                retweet_count int unsigned,
                retweeted_status_id bigint unsigned,
                truncated boolean,
                entities varchar(1024),
                primary key (id, created_at)
            )
            default charset=UTF8 engine=InnoDB
            partition by range (to_days(created_at))(
                partition prt_#{today} values less than (to_days('#{next_day}')),
                partition prt_max values less than MAXVALUE
            )
        EOS
        execute <<-EOS
            create table users (
                id int unsigned,
                screen_name varchar(20),
                name varchar(128),
                description varchar(512),
                url varchar(128),
                lang varchar(2),
                created_at datetime,
                utc_offset int,
                time_zone varchar(128),
                location varchar(128),
                statuses_count int unsigned,
                favourites_count int unsigned,
                friends_count int unsigned,
                followers_count int unsigned,
                listed_count int unsigned,
                protected boolean,
                default_profile boolean,
                default_profile_image boolean,
                verified boolean,
                contributors_enabled boolean,
                profile_image_url varchar(128),
                profile_background_image_url varchar(128),
                primary key (id),
                index (screen_name)
            )
            default charset=UTF8 engine=InnoDB
        EOS
    end

    def self.down
        drop_table :tweets
        drop_table :users
    end
end
