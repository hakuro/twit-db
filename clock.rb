#!/usr/bin/env ruby

require 'clockwork'
include Clockwork

handler do |job|
    Thread.new do
        begin
            job.call
        rescue => exc
            puts exc
        end
    end
end

pid = nil
watch_dog = lambda do
    command = "bundle exec ruby twit.rb"
    unless pid
        pid = Process.spawn(command)
        Process.waitpid(pid)
        pid = nil
    end
end
every( 10.minutes, watch_dog)

append_partition = lambda do
    command = "bundle exec ruby append.rb"
    Process.spawn(command)
end
every( 1.day, append_partition, :at => '23:50')

