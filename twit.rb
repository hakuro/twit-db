#!/usr/bin/env ruby
# _*_ coding: utf-8 _*_

require "date"
require "json"
require "net/http"
require "cgi"
require "yaml"
require "rubygems"
require "active_record"

class StreamReceiver
    def initialize(username, password, uri, options, wait=30, max_wait=480)
        @wait = wait
        @min_wait = wait
        @max_wait = max_wait
        @username = username
        @password = password
        stream_uri = uri
        stream_uri += "?" + options.to_a.map{|i| i.join("=")}.join("&") if options
        @uri = URI.parse(stream_uri)
    end

    def setup
        @http = Net::HTTP.new(@uri.host, @uri.port)
        @http.use_ssl = true
        @http.start
        @request = Net::HTTP::Get.new(@uri.request_uri)
        @request.basic_auth(@username, @password)
    end

    def request
        begin
            @http.request(@request) do |response|
                response.read_body do |body|
                    status = JSON.parse(body) rescue next
                    next unless status["text"]
                    yield status
                end
            end
        ensure
            @http.finish
        end
    end

    def start
        while 1 do
            begin
                self.setup
                self.request{|status|
                    yield status
                    @wait = @min_wait
                }
            rescue => exc
                puts exc
                sleep @wait
                @wait *= 2 if @wait < @max_wait
            end
        end
    end
end

if __FILE__ == $0
    # setup stream
    tw = YAML.load_file("config/twitter.yaml")
    track = tw["search_char"].join.scan(/./) + tw["search_texts"]
    ["", nil].each{|i| track.delete(i) }
    options = tw["options"]
    options ||= {}
    options["track"] = track.map{|i| CGI.escape(i) }.join(",")

    stream = StreamReceiver.new(
        tw["user_name"].unpack("m")[0],
        tw["password"].unpack("m")[0],
        tw["stream_uri"],
        options
    )

    # setup activerecord
    ActiveRecord::Base.configurations = YAML.load_file("config/database.yaml")
    ActiveRecord::Base.establish_connection('production')

    class Tweet < ActiveRecord::Base
        self.primary_key = :id
    end
    tweet_cols = Tweet.columns.map{|c| c.name}

    class User < ActiveRecord::Base
    end
    user_cols = User.columns.map{|c| c.name}

    def save(id, attr, record)
        if record.exists?(id)
            row = record.find(id)
            row.attributes = attr
        else
            row = record.new(attr)
            row.id = id
        end
        row.save!
    end

    def format_date(str)
        Time.strptime(str.gsub(/\+0000/, "GMT"), "%a %b %d %X %Z %Y")
    end

    # start receive
    stream.start{|s|
        u = s["user"]
        attr = {
            :created_at => format_date(s["created_at"]),
            :user_id => u["id"],
            :retweeted_status_id => s["retweeted"] ? s["retweeted"]["id"] : nil,
            :entities => s["entities"].to_s
        }
        tweet_cols.each{|c| attr[c.to_sym] ||= s[c]}
        save(s["id"].to_i, attr, Tweet)

        attr = {
            :created_at => format_date(u["created_at"])
        }
        user_cols.each{|c| attr[c.to_sym] ||= u[c]}
        save(u["id"].to_i, attr, User)
    }
end

